/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit
import class Foundation.FileHandle
import class Foundation.FileManager

/// Protocol for reading and writing to a stream.
public protocol StreamReader: AnyObject {
    /// The number of bytes that are available for reading.
    var availableForRead: UInt { get }

    /// Return true, if there is no more data to read.
    var isEmpty: Bool { get }

    /// Whether or not the stream has finished writing.
    /// This is used to determine when to stop reading from the stream.
    var hasFinishedWriting: Bool {get set}

    /// Read up to a maximum number of bytes on a stream that is opened..
    /// - Parameters:
    ///  - maxBytes: The maximum number of bytes to read.  If nil, will read all bytes.
    /// - rewind: Whether or not to rewind the stream after reading.
    func read(maxBytes: UInt?, rewind: Bool) -> ByteBuffer

    /// Read async up to a maximum number of bytes on a stream that is opened..
    /// - Parameters:
    ///  - count: The maximum number of bytes to read.  If nil, will read all bytes.
    /// - rewind: Whether or not to rewind the stream after reading.
    func read(upToCount count: Int?) async throws -> Data?

    /// Seek to a specific offset in the stream.
    /// - Parameter offset: The offset to seek to. This is relative to the beginning of the stream.
    func seek(offset: Int) throws

    /// Close the stream.
    /// - Parameter error: The error that caused the stream to close.
    func onError(error: ClientError)

    /// Write a buffer to the stream.
    /// - Parameter buffer: The buffer to write to the stream.
    func write(buffer: ByteBuffer)
}

extension StreamReader {
    public var isEmpty: Bool {
        // swiftlint:disable empty_count
        return availableForRead == 0
        // swiftlint:enable empty_count
    }
}

extension ByteBuffer {
    public var isEmpty: Bool {
        return getData().isEmpty
    }
}
