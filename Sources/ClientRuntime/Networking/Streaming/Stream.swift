//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

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
public protocol WriteableStream: AnyObject {
    ///  Writes the contents of `data` to the stream
    /// - Parameter data: data to write
    func write(contentsOf data: Data) throws

    /// Closes the stream
    func close()

    func closeWithError(_ error: Error)
}

/// Protocol that provides reading and writing data to a stream
public protocol Stream: ReadableStream, WriteableStream {
}

public enum StreamError: Error {
    case invalidOffset(String)
    case notSupported(String)
}

extension Stream {
    public func seek(toOffset offset: Int) throws {
        guard isSeekable else {
            throw StreamError.notSupported("Seeking is not supported.")
        }
    }
}
