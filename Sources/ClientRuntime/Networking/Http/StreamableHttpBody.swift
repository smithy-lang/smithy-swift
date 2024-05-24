//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum SmithyStreamsAPI.StreamError
import AwsCommonRuntimeKit

/// A class that implements the `IStreamable` protocol for `ByteStream`.
/// It acts as a bridge between AWS SDK and CRT.
class StreamableHttpBody: IStreamable {

    var position: Data.Index
    let body: ByteStream
    let logger: SwiftLogger

    init(body: ByteStream) {
        self.body = body

        switch body {
        case .data(let data):
            position = data?.startIndex ?? .min
        case .stream(let stream):
            position = stream.position
        case .noStream:
            position = .min
        }

        logger = SwiftLogger(label: "HttpContent")
    }

    /// Returns the length of the stream
    /// - Returns: The length of the stream
    /// if not available, returns 0
    func length() throws -> UInt64 {
        switch body {
        case .data(let data):
            return UInt64(data?.count ?? 0)
        case .stream(let stream):
            return UInt64(stream.length ?? 0)
        case .noStream:
            return 0
        }
    }

    /// Seeks to the specified offset in the stream
    /// - Parameters:
    ///   - offset: offset to seek to
    ///   - streamSeekType: type of seek
    func seek(offset: Int64, streamSeekType: AwsCommonRuntimeKit.StreamSeekType) throws {
        guard streamSeekType == .begin else {
            throw StreamError.notSupported("Seeking from end is not supported."
                                           + " Only seeking from beginning is supported.")
        }

        switch body {
        case .data(let data):
            guard let data = data else {
                position = .min
                return
            }
            position = data.startIndex.advanced(by: Int(offset))
            logger.debug("seeking to offset \(offset) in data")
        case .stream(let stream):
            guard stream.isSeekable else {
                logger.debug("stream doesn't support seeking, skip seeking.")
                return
            }
            logger.debug("seeking to offset \(offset) in data")
            try stream.seek(toOffset: Int(offset))
        case .noStream:
            position = .min
        }
    }

    func read(buffer: UnsafeMutableBufferPointer<UInt8>) throws -> Int? {
        switch body {
        case .data(let data):
            guard let data = data else {
                return nil
            }
            let toRead = min(buffer.count, data.count - position)
            data.copyBytes(to: buffer, from: position..<position.advanced(by: toRead))
            position = position.advanced(by: toRead)
            logger.debug("read \(toRead) bytes from data")
            if toRead == 0 && data.endIndex == position {
                return nil
            }
            return toRead
        case .stream(let stream):
            guard let data = try stream.read(upToCount: buffer.count) else {
                return nil
            }
            data.copyBytes(to: buffer, from: data.startIndex..<data.endIndex)
            position = position.advanced(by: data.count)
            logger.debug("read \(data.count) bytes from stream")
            if data.isEmpty && stream.position == stream.length {
                return nil
            }
            return data.count
        case .noStream:
            return nil
        }
    }
}
