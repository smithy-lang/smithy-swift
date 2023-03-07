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

    /// The length of the stream, if known.
    public private(set) var length: Int?

    /// The current position in the stream.
    public private(set) var position: Data.Index

    /// Whether the stream is empty.
    public var isEmpty: Bool {
        return buffer.isEmpty
    }

    /// Whether the stream is seekable.
    /// Although this stream is seekable, seeking to a position that is not in the buffer will cause the stream to throw an error.
    public var isSeekable: Bool {
        return false
    }

    private var isClosed: Bool

    private(set) var buffer = Data()
    private let lock = NSRecursiveLock()

    /// Initializes a new `BufferedStream` instance.
    /// - Parameters:
    ///   - data: The initial data to buffer.
    ///   - isClosed: Whether the stream is closed.
    public init(data: Data = .init(), isClosed: Bool = false) {
        self.buffer = data
        self.position = data.startIndex
        self.length = data.count
        self.isClosed = isClosed
    }

    /// Reads up to `count` bytes from the stream.
    /// - Parameter count: The maximum number of bytes to read.
    /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available.
    public func read(upToCount count: Int) throws -> Data? {
        lock.withLockingClosure {
            let toRead = min(count, buffer.count)
            let endPosition = position.advanced(by: toRead)
            let chunk = buffer[position..<endPosition]

            // remove the data we just read
            buffer.removeFirst(toRead)

            // update position
            position = endPosition

            // if we're closed and there's no data left, return nil
            // this will signal the end of the stream
            if isClosed && chunk.isEmpty {
                return nil
            }

            return chunk
        }
    }

    /// Reads all data from the stream.
    /// It uses `read(upToCount:)` to read data in chunks.
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

    /// Seeks to the specified offset in the stream.
    /// - Parameter offset: The offset to seek to.
    public func seek(toOffset offset: Int) throws {
        try lock.withLockingThrowingClosure {
            let newPosition = buffer.startIndex.advanced(by: offset)

            // make sure the new position is within the bounds of the buffer
            guard newPosition >= buffer.startIndex && newPosition <= buffer.endIndex else {
                throw StreamError.invalidOffset("Invalid offset: \(offset)")
            }

            position = newPosition
        }
    }

    /// Writes the specified data to the stream.
    /// - Parameter data: The data to write.
    public func write(contentsOf data: Data) throws {
        lock.withLockingClosure {
            // append the data to the buffer
            // this will increase the in-memory size of the buffer
            buffer.append(data)
            length = (length ?? 0) + data.count
        }
    }

    /// Closes the stream.
    public func close() throws {
        lock.withLockingClosure {
            isClosed = true
        }
    }
}
