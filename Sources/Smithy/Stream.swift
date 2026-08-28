//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

/// Protocol that provides reading data from a stream
public protocol ReadableStream: AnyObject, Sendable {
    /// Returns the current position in the stream
    var position: Data.Index { get }

    /// Returns the length of the stream, if known
    var length: Int? { get }

    /// Returns true if the stream is empty, false otherwise
    var isEmpty: Bool { get }

    /// Returns true if the stream is seekable, false otherwise
    var isSeekable: Bool { get }

    /// Reads up to `count` bytes from the stream
    /// - Parameter count: maximum number of bytes to read
    /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available
    func read(upToCount count: Int) throws -> Data?

    /// Reads up to `count` bytes from the stream asynchronously
    /// - Parameter count: maximum number of bytes to read
    /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available
    func readAsync(upToCount count: Int) async throws -> Data?

    /// Reads all remaining bytes from the stream, blocking the calling thread until the stream closes.
    /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available
    func readToEnd() throws -> Data?

    /// Reads all remaining bytes from the stream asynchronously.
    /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available
    func readToEndAsync() async throws -> Data?

    /// Seeks to the specified offset within the stream
    /// - Parameter offset: offset to seek to
    func seek(toOffset offset: Int) throws
}

/// Protocol that provides writing data to a stream
public protocol WriteableStream: AnyObject, Sendable {
    ///  Writes the contents of `data` to the stream
    /// - Parameter data: data to write
    func write(contentsOf data: Data) throws

    /// Writes the contents of `data` to the stream asynchronously.
    ///
    /// Unlike the synchronous `write(contentsOf:)`, an async write lets a stream apply
    /// backpressure: a conforming stream may suspend the caller until the data has been
    /// consumed (or until buffered data drops below a high-water mark), so a fast producer
    /// cannot grow the stream's buffer without bound.
    ///
    /// A default implementation is provided that simply calls the synchronous
    /// `write(contentsOf:)`, so existing conformers compile unchanged and gain a (non-suspending)
    /// async entry point for free.  Streams that support backpressure should override this.
    ///
    /// - Note: This is intentionally a distinct method name (not an `async` overload of
    ///   `write(contentsOf:)`). Overloading the existing synchronous method with an `async`
    ///   variant of the same name would be source-breaking: in an `async` context Swift prefers
    ///   the async overload, so existing call sites that write `try stream.write(contentsOf:)`
    ///   would suddenly require `try await`. The `writeAsync` name mirrors the existing
    ///   `read` / `readAsync` and `readToEnd` / `readToEndAsync` convention and avoids that hazard.
    /// - Parameter data: data to write
    func writeAsync(contentsOf data: Data) async throws

    /// Closes the stream
    func close()

    func closeWithError(_ error: Error)
}

public extension WriteableStream {
    /// Default async write: bridges to the synchronous `write(contentsOf:)`.
    ///
    /// This default keeps the new `writeAsync(contentsOf:)` requirement source-compatible for all
    /// existing conformers — they need no code change and inherit this implementation.
    func writeAsync(contentsOf data: Data) async throws {
        try self.write(contentsOf: data)
    }
}

/// Protocol that provides reading and writing data to a stream
public protocol Stream: ReadableStream, WriteableStream {
}

public enum StreamError: Error, Sendable {
    case invalidOffset(String)
    case notSupported(String)
    case connectionReleased(String)
    case writeToClosedStream(String)
}

extension Stream {
    public func seek(toOffset offset: Int) throws {
        guard isSeekable else {
            throw StreamError.notSupported("Seeking is not supported.")
        }
    }
}

/*
 * Default chunk size
 */
public let CHUNK_SIZE_BYTES: Int = 65_536

public extension Stream {
    var isEligibleForChunkedStreaming: Bool {
        return self.length != nil
    }
}
