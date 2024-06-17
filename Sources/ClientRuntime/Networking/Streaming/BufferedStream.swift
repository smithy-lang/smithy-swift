//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import struct Foundation.Data
import class Foundation.NSRecursiveLock

/// A `Stream` implementation that buffers data in memory.
/// The buffer size depends on the amount of data written and read.
/// Note: This class is thread-safe and async-safe.
/// Note: if data is not read from the stream, the buffer will grow indefinitely until the stream is closed.
///       or reach the maximum size of a `Data` object.
public class BufferedStream: Stream {

    /// Returns the cumulative length of all data so far written to the stream, if known.
    /// For a buffered stream, the length will only be known if the stream has closed.
    public var length: Int? {
        lock.withLockingClosure {
            _length
        }
    }

    /// Access this value only while `lock` is locked, to prevent simultaneous access.
    private var _length: Int?

    /// Returns the current position in the stream
    public var position: Data.Index {
        lock.withLockingClosure {
            _position
        }
    }

    /// Access this value only while `lock` is locked, to prevent simultaneous access.
    private var _position: Data.Index

    /// Returns true if the in-memory buffer is empty, false otherwise
    public var isEmpty: Bool {
        lock.withLockingClosure {
            return _buffer.isEmpty == true
        }
    }

    /// Returns false, buffered streams are not seekable.
    public var isSeekable: Bool { false }

    /// Returns whether the stream has been closed.  Defaults to `false` on stream creation.
    public var isClosed: Bool {
        lock.withLockingClosure {
            return _isClosed
        }
    }

    /// Access this value only while `lock` is locked, to prevent simultaneous access.
    private var _isClosed: Bool

    /// Contains data that has been written to this stream, but not yet read.
    ///
    /// Access this value only while `lock` is locked, to prevent simultaneous access.
    private var _buffer: Data

    /// The number of bytes currently in the buffer, awaiting read.
    public var bufferCount: Int {
        lock.withLockingClosure {
            _buffer.count
        }
    }

    /// The number of bytes that have been written to this stream, including the initial data at creation.
    ///
    /// Access this value only while `lock` is locked, to prevent simultaneous access.
    private var _dataCount: Int

    private var _error: Error?

    /// When locked, this `NSRecursiveLock` grants safe, exclusive access to the properties on this type.
    /// Note: `NSRecursiveLock` is `@Sendable` so it is safe to use with Swift concurrency.
    private let lock = NSRecursiveLock()

    /// Holds a continuation and the requested byte count for a stream reader.
    /// Readers are stored in the `readers` queue until data is available to return.
    private struct SuspendedReader {
        /// The continuation for this reader.
        let continuation: CheckedContinuation<Data?, Error>
        /// The maximum number of bytes to be returned to this reader.
        ///
        /// This is just the `count` parameter to `read(upToCount:)` for the suspended read.
        /// This is set to `Int.max` when reading to end-of-stream.
        let byteCount: Int
        /// `true` if this reader should read to the end, `false` otherwise.
        let readsToEnd: Bool
    }

    /// Contains suspended readers that are awaiting data from the stream, if any.
    /// This array is maintained as a first-in, first-out queue,
    /// where the newest reader is at the end of the array,
    /// and the oldest / next reader is at the beginning.
    ///
    /// Access this value only while `lock` is locked, to prevent simultaneous access.
    private var _readers: [SuspendedReader] = []

    /// Initializes a new `BufferedStream` instance.
    /// - Parameters:
    ///   - data: The initial data to buffer.
    ///   - isClosed: Whether the stream is closed.
    public init(data: Data? = nil, isClosed: Bool = false) {
        self._buffer = data ?? Data()
        self._position = _buffer.startIndex
        self._dataCount = _buffer.count
        self._isClosed = isClosed
        if isClosed { _length = _buffer.count }
    }

    /// If this task is released while it still has suspended readers, continue all readers with nil data
    /// so no continuations are left un-continued and readers are informed that the stream is closed.
    deinit {
        _readers.forEach { $0.continuation.resume(returning: nil) }
    }

    /// Reads up to `count` bytes from the stream.
    /// - Parameter count: The maximum number of bytes to read.
    /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available.
    public func read(upToCount count: Int) throws -> Data? {
        try lock.withLockingClosure {
            try _read(upToCount: count)
        }
    }

    /// Call this function only while `lock` is locked, to prevent simultaneous access.
    private func _read(upToCount count: Int) throws -> Data? {

        // throw any previously stored error, if there was one
        // dispose of the error when throwing so it is only thrown once
        if let error = _error {
            _error = nil
            throw error
        }
        let toRead = min(count, _buffer.count)
        let endPosition = position.advanced(by: toRead)
        let chunk = _buffer[position..<endPosition]

        // remove the data we just read
        _buffer.removeFirst(toRead)

        // update position
        _position = endPosition

        // if we're closed and there's no data left, return nil
        // this will signal the end of the stream
        if _isClosed && chunk.isEmpty == true {
            return nil
        }

        return chunk
    }

    /// Reads from the stream asynchronously.  Readers will suspend if no data is currently available.
    /// - Parameter count: The maximum number of bytes to be returned to the caller.
    /// - Returns: A chunk of data from the stream.
    public func readAsync(upToCount count: Int) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            lock.withLockingClosure {
                // Add a new reader to the queue, then service the readers if any data is waiting.
                let reader = SuspendedReader(continuation: continuation, byteCount: count, readsToEnd: false)
                _readers.append(reader)
                _serviceReadersIfPossible()
            }
        }
    }

    /// Reads all data from the stream.
    /// It uses `read(upToCount:)` to read data in chunks.
    /// This function will block and wait until the stream is closed before returning the data read from the stream.
    /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available.
    public func readToEnd() throws -> Data? {
        var data = Data()

        while let next = try read(upToCount: Int.max) {
            data.append(next)
        }

        return lock.withLockingClosure {
            // if we're closed and there's no data left, return nil
            // this will signal the end of the stream
            if _isClosed && data.isEmpty {
                return nil
            }

            return data
        }
    }

    public func readToEndAsync() async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            lock.withLockingClosure {
                // Add a new reader to the queue, then service the readers if any data is waiting.
                let reader = SuspendedReader(continuation: continuation, byteCount: Int.max, readsToEnd: true)
                _readers.append(reader)
                _serviceReadersIfPossible()
            }
        }
    }

    /// Writes the specified data to the stream.
    /// Then, continues a suspended reader (if any) to read the data.
    /// - Parameter data: The data to write.
    public func write(contentsOf data: Data) throws {
        lock.withLockingClosure {
            // append the data to the buffer
            // this will increase the in-memory size of the buffer
            _buffer.append(data)
            _dataCount += data.count
            // If any clients are waiting to read data, service them.
            _serviceReadersIfPossible()
        }
    }

    /// Closes the stream.
    public func close() {
        close(error: nil)
    }

    /// Closes the stream.
    public func closeWithError(_ error: Error) {
        close(error: error)
    }

    private func close(error: Error?) {
        lock.withLockingClosure {
            guard !_isClosed else { return }
            _isClosed = true
            _length = _dataCount
            if let error { _error = error }
            _serviceReadersIfPossible()
        }
    }

    /// If there is a client waiting to read data, and there is unread data remaining in the buffer,
    /// read the data and pass it to the reader via the continuation.
    /// Continue until there are no clients or no data.
    ///
    /// Call this function only while `lock` is locked, to prevent simultaneous access.
    private func _serviceReadersIfPossible() {
        while !_readers.isEmpty {
            let suspendedReader = _readers[0]  // Don't remove the client from the array yet
            do {
                let data: Data?
                if suspendedReader.readsToEnd {
                    guard _isClosed else { return }  // Don't read until the stream closes when reading to end
                    data = try _read(upToCount: suspendedReader.byteCount)
                    _ = _readers.removeFirst()
                } else {
                    data = try _read(upToCount: suspendedReader.byteCount)
                    if let data, data.isEmpty { return }  // this means stream is still open but has no data
                    _ = _readers.removeFirst()
                }
                suspendedReader.continuation.resume(returning: data)
            } catch {
                _ = _readers.removeFirst()
                suspendedReader.continuation.resume(throwing: error)
            }
        }
    }
}
