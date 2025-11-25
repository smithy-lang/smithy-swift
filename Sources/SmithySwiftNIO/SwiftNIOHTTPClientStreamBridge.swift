//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AsyncHTTPClient
import Foundation
import NIO
import Smithy
import SmithyStreams

/// Handles streaming between Smithy streams and AsyncHTTPClient
final class SwiftNIOHTTPClientStreamBridge {

    /// Convert Smithy ByteStream to AsyncHTTPClient request body
    static func convertRequestBody(
        from body: ByteStream,
        allocator: ByteBufferAllocator,
        chunkSize: Int = CHUNK_SIZE_BYTES
    ) async throws
        -> AsyncHTTPClient.HTTPClientRequest.Body {
        switch body {
        case .noStream:
            // No body to send
            return .bytes(allocator.buffer(capacity: 0))

        case .data(let data):
            // Convert Data to ByteBuffer
            if let data = data {
                var buffer = allocator.buffer(capacity: data.count)
                buffer.writeBytes(data)
                return .bytes(buffer)
            } else {
                return .bytes(allocator.buffer(capacity: 0))
            }

        case .stream(let stream):
            // Handle streaming request body
            return try await convertStreamToRequestBody(
                stream: stream,
                allocator: allocator,
                chunkSize: chunkSize
            )
        }
    }

    /// Convert AsyncHTTPClient response body to Smithy ByteStream
    static func convertResponseBody(
        from response: AsyncHTTPClient.HTTPClientResponse
    ) async -> ByteStream {
        let bufferedStream = BufferedStream()

        do {
            var iterator = response.body.makeAsyncIterator()
            while let buffer = try await iterator.next() {
                // Convert ByteBuffer to Data and write to buffered stream
                if let bytes = buffer.getBytes(
                    at: buffer.readerIndex,
                    length: buffer.readableBytes
                ) {
                    let data = Data(bytes)
                    try bufferedStream.write(contentsOf: data)
                }
            }
            bufferedStream.close()
        } catch {
            bufferedStream.closeWithError(error)
        }

        return .stream(bufferedStream)
    }

    /// Convert a Smithy Stream to AsyncHTTPClient request body
    private static func convertStreamToRequestBody(
        stream: Smithy.Stream,
        allocator: ByteBufferAllocator,
        chunkSize: Int = CHUNK_SIZE_BYTES
    ) async throws -> AsyncHTTPClient.HTTPClientRequest.Body {
        let asyncSequence = StreamToAsyncSequence(
            stream: stream,
            allocator: allocator,
            chunkSize: chunkSize
        )

        // Use known length if available, unless the stream is eligible for chunked streaming.
        if let length = stream.length, !stream.isEligibleForChunkedStreaming {
            return .stream(asyncSequence, length: .known(Int64(length)))
        } else {
            return .stream(asyncSequence, length: .unknown)
        }
    }
}

/// AsyncSequence adapter that converts a Smithy Stream to ByteBuffer sequence for AsyncHTTPClient
internal struct StreamToAsyncSequence: AsyncSequence, Sendable {
    typealias Element = ByteBuffer

    private let stream: Smithy.Stream
    private let allocator: ByteBufferAllocator
    private let chunkSize: Int

    init(
        stream: Smithy.Stream,
        allocator: ByteBufferAllocator,
        chunkSize: Int = CHUNK_SIZE_BYTES
    ) {
        self.stream = stream
        self.allocator = allocator
        self.chunkSize = chunkSize
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(stream: stream, allocator: allocator, chunkSize: chunkSize)
    }

    struct AsyncIterator: AsyncIteratorProtocol {
        private let stream: Smithy.Stream
        private let allocator: ByteBufferAllocator
        private let chunkSize: Int
        private var isFinished = false

        init(stream: Smithy.Stream, allocator: ByteBufferAllocator, chunkSize: Int) {
            self.stream = stream
            self.allocator = allocator
            self.chunkSize = chunkSize
        }

        mutating func next() async throws -> ByteBuffer? {
            guard !isFinished else { return nil }

            do {
                // Read a chunk from the stream (using configurable chunk size)
                let data = try await stream.readAsync(upToCount: chunkSize)

                if let data = data, !data.isEmpty {
                    var buffer = allocator.buffer(capacity: data.count)
                    buffer.writeBytes(data)
                    return buffer
                } else {
                    isFinished = true
                    stream.close()
                    return nil
                }
            } catch {
                isFinished = true
                stream.close()
                throw SwiftNIOHTTPClientError.streamingError(error)
            }
        }
    }
}
