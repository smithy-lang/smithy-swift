//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A `Stream` implementation that buffers data in memory.
/// The buffer size depends on the amount of data written and read.
/// Note: This class is thread-safe.
/// Note: if data is not read from the stream, the buffer will grow indefinitely until the stream is closed.
///       or reach the maximum size of a `Data` object.
public class BufferedStream: Stream {
    /// Returns the length of the stream, if known
    public private(set) var length: Int?

    /// Returns the current position in the stream
    public private(set) var position: Data.Index

    /// Returns true if the stream is empty, false otherwise
    public var isEmpty: Bool {
        return buffer?.isEmpty == true
    }

    /// Returns false, buffered streams are not seekable
    public let isSeekable: Bool = false

    private var isClosed: Bool

    private(set) var buffer: Data?
    private let lock = NSRecursiveLock()

    /// Continuations that are awaiting data, and the byte count to be delivered to each.
    /// Access to this value should only occur while `lock` is locked.
    private var clients: [(UnsafeContinuation<Data?, Error>, Int)] = []

    /// Initializes a new `BufferedStream` instance.
    /// - Parameters:
    ///   - data: The initial data to buffer.
    ///   - isClosed: Whether the stream is closed.
    public init(data: Data? = .init(), isClosed: Bool = false) {
        self.buffer = data
        self.position = data?.startIndex ?? 0
        self.length = data?.count
        self.isClosed = isClosed
    }

    /// Reads up to `count` bytes from the stream.
    /// - Parameter count: The maximum number of bytes to read.
    /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available.
    public func read(upToCount count: Int) throws -> Data? {
        try lock.withLockingThrowingClosure {
            try _read(upToCount: count)
        }
    }

    private func _read(upToCount count: Int) throws -> Data? {
        let toRead = min(count, buffer?.count ?? 0)
        let endPosition = position.advanced(by: toRead)
        let chunk = buffer?[position..<endPosition]

        // remove the data we just read
        buffer?.removeFirst(toRead)

        // update position
        position = endPosition

        // if we're closed and there's no data left, return nil
        // this will signal the end of the stream
        if isClosed && chunk?.isEmpty == true {
            return nil
        }

        return chunk
    }

    /// Reads from the stream asynchronously.  Readers will suspend if no data is currently available.
    /// - Parameter count: The maximum number of bytes to be returned to the caller.
    /// - Returns: A chunk of data from the stream.
    public func readAsync(upToCount count: Int) async throws -> Data? {
        try await withUnsafeThrowingContinuation { continuation in
            lock.withLockingClosure {
                // Add a new client to the list, then service the next client if any data is waiting.
                let client = (continuation, count)
                clients.append(client)
                _flushToNextClient()
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
            if isClosed && data.isEmpty {
                return nil
            }

            return data
        }
    }

    /// Writes the specified data to the stream.
    /// - Parameter data: The data to write.
    public func write(contentsOf data: Data) throws {
        try lock.withLockingThrowingClosure {
            // append the data to the buffer
            // this will increase the in-memory size of the buffer
            buffer?.append(data)
            length = (length ?? 0) + data.count
            // If any clients are waiting to read data, service them.
            _flushToNextClient()
        }
    }

    /// Closes the stream.
    public func close() throws {
        lock.withLockingClosure {
            isClosed = true
        }
    }

    // If there is a client waiting to read data, and there is unread data remaining in the buffer,
    // read the data and pass it to the reader via the continuation.
    // Continue until there are no clients or no data.
    private func _flushToNextClient() {
        while !clients.isEmpty {
            let (continuation, count) = clients[0]  // Don't remove the client from the array yet
            do {
                guard let data = try _read(upToCount: count), !data.isEmpty else { return }
                _ = clients.removeFirst()
                continuation.resume(returning: data)
            } catch {
                _ = clients.removeFirst()
                continuation.resume(throwing: error)
            }
        }
    }
}
