//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit

/// Protocol that provides reading data from a stream
public protocol ReadableStream: AnyObject {
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

    /// Reads all remaining bytes from the stream
    /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available
    func readToEnd() throws -> Data?

    /// Seeks to the specified offset within the stream
    /// - Parameter offset: offset to seek to
    func seek(toOffset offset: Int) throws
}

/// Protocol that provides writing data to a stream
public protocol WriteableStream: AnyObject {
    ///  Writes the contents of `data` to the stream
    /// - Parameter data: data to write
    func write(contentsOf data: Data) throws

    /// Closes the stream
    func close() throws
}

/// Protocol that provides reading and writing data to a stream
public protocol Stream: ReadableStream, WriteableStream {
}

public enum StreamError: Error {
    case invalidOffset(String)
    case notSupported(String)
}

extension Stream {
    func isEqual(to other: Stream) throws -> Bool {
        let selfData = try readToEnd()
        let otherData = try other.readToEnd()
        return selfData == otherData
    }
}

extension Stream {
    public func seek(toOffset offset: Int) throws {
        guard isSeekable else {
            throw StreamError.notSupported("Seeking is not supported.")
        }
    }
}

extension Stream {
    /// Reads up to `count` bytes from the stream asynchronously.
    /// This is a default implementation that calls `read(upToCount:)` using Swift Concurrency.
    /// Depending on the current position in the stream, this may read from the cache or the base stream.
    /// - Parameter count: The maximum number of bytes to read.
    /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available.
    public func readAsync(upToCount count: Int) async throws -> Data? {
        try await withUnsafeThrowingContinuation { continuation in
            Task {
                do {
                    let data = try read(upToCount: count)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
