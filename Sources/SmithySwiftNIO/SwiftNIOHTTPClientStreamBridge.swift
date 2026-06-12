//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AsyncHTTPClient
import Foundation
import NIOCore
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

    /// Convert AsyncHTTPClient response body to Smithy ByteStream.
    ///
    /// The response body is bridged into a `ByteBufferStream`, which holds NIO `ByteBuffer`s
    /// directly — the inbound buffers are appended without the `getBytes` → `[UInt8]` → `Data`
    /// round-trip the legacy path performed. Bridging happens on a detached task and is pulled
    /// lazily with backpressure (`writeBufferAsync` suspends when the stream's buffer is full),
    /// so the socket is not drained into memory faster than the consumer reads.
    static func convertResponseBody(
        from response: AsyncHTTPClient.HTTPClientResponse
    ) async -> ByteStream {
        let stream = ByteBufferStream()

        // Pull the NIO response body on a background task so backpressure can flow:
        // `writeBufferAsync` suspends this loop when the stream is full, which stops us
        // pulling `iterator.next()`, which lets NIO's high/low watermark throttle the socket.
        Task {
            do {
                var iterator = response.body.makeAsyncIterator()
                while let buffer = try await iterator.next() {
                    try await stream.writeBufferAsync(buffer)  // zero-copy append (COW)
                }
                stream.close()
            } catch {
                stream.closeWithError(error)
            }
        }

        return .stream(stream)
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
                // Fast path: if the source is a ByteBufferStream, pull a ByteBuffer slice
                // directly (zero-copy COW) instead of round-tripping through Data + a fresh
                // ByteBuffer allocation.
                if let fast = stream as? ByteBufferStream {
                    if let buffer = try await fast.readBufferAsync(upToCount: chunkSize),
                       buffer.readableBytes > 0 {
                        return buffer
                    } else {
                        isFinished = true
                        stream.close()
                        return nil
                    }
                }

                // Default path: read a Data chunk and copy it into a fresh ByteBuffer.
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
