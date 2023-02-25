//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit

/// Protocol that provides reading data from a stream
public protocol ReadableStream: AnyObject {
    /// The current position within the stream
    var position: Data.Index { get }

    /// The length of the stream in bytes, if known
    var length: Int? { get }

    /// Whether the stream is empty
    var isEmpty: Bool { get }

    /// Read up to `count` bytes from the stream
    /// - Parameter count: maximum number of bytes to read
    /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available
    func read(upToCount count: Int) throws -> Data?

    /// Read all remaining bytes from the stream
    /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available
    func readToEnd() throws -> Data?

    /// Seek to the specified offset within the stream
    /// - Parameter offset: offset to seek to
    func seek(toOffset offset: Int) throws
}

/// Protocol that provides writing data to a stream
public protocol WriteableStream: AnyObject {
    ///  Write the contents of `data` to the stream
    /// - Parameter data: data to write
    func write(contentsOf data: Data) throws

    /// Close the stream
    func close() throws
}

/// Protocol that provides reading and writing data to a stream
public protocol Stream: ReadableStream, WriteableStream {
}

public enum StreamError: Error {
    case invalidOffset(String)
    case notSupported(String)
}
