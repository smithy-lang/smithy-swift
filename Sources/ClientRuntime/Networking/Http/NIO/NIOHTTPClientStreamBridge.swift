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
final class NIOHTTPClientStreamBridge {

    /// Convert Smithy ByteStream to AsyncHTTPClient request body
    static func convertRequestBody(
        from body: ByteStream,
        allocator: ByteBufferAllocator
    ) async throws -> AsyncHTTPClient.HTTPClientRequest.Body {
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
            return try await convertStreamToRequestBody(stream: stream, allocator: allocator)
        }
    }

    /// Convert AsyncHTTPClient response body to Smithy ByteStream
    static func convertResponseBody(
        from response: AsyncHTTPClient.HTTPClientResponse
    ) -> ByteStream {
        let bufferedStream = BufferedStream()

        // Start a background task to stream data from AsyncHTTPClient to BufferedStream
        Task {
            do {
                var iterator = response.body.makeAsyncIterator()
                while let buffer = try await iterator.next() {
                    // Convert ByteBuffer to Data and write to buffered stream
                    if let bytes = buffer.getBytes(at: buffer.readerIndex, length: buffer.readableBytes) {
                        let data = Data(bytes)
                        try bufferedStream.write(contentsOf: data)
                    }
                }
                bufferedStream.close()
            } catch {
                bufferedStream.closeWithError(error)
            }
        }

        return .stream(bufferedStream)
    }

    /// Convert a Smithy Stream to AsyncHTTPClient request body
    private static func convertStreamToRequestBody(
        stream: Smithy.Stream,
        allocator: ByteBufferAllocator
    ) async throws -> AsyncHTTPClient.HTTPClientRequest.Body {
        if let streamLength = stream.length {
            let asyncSequence = StreamToAsyncSequence(stream: stream, allocator: allocator)
            return .stream(asyncSequence, length: .known(Int64(streamLength)))
        } else {
            do {
                let data = try await stream.readToEndAsync()
                if let data = data {
                    var buffer = allocator.buffer(capacity: data.count)
                    buffer.writeBytes(data)
                    return .bytes(buffer)
                } else {
                    return .bytes(allocator.buffer(capacity: 0))
                }
            } catch {
                throw NIOHTTPClientError.streamingError(error)
            }
        }
    }
}

/// AsyncSequence adapter that converts a Smithy Stream to ByteBuffer sequence for AsyncHTTPClient
internal struct StreamToAsyncSequence: AsyncSequence, Sendable {
    typealias Element = ByteBuffer

    private let stream: Smithy.Stream
    private let allocator: ByteBufferAllocator

    init(stream: Smithy.Stream, allocator: ByteBufferAllocator) {
        self.stream = stream
        self.allocator = allocator
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(stream: stream, allocator: allocator)
    }

    struct AsyncIterator: AsyncIteratorProtocol {
        private let stream: Smithy.Stream
        private let allocator: ByteBufferAllocator
        private var isFinished = false

        init(stream: Smithy.Stream, allocator: ByteBufferAllocator) {
            self.stream = stream
            self.allocator = allocator
        }

        mutating func next() async throws -> ByteBuffer? {
            guard !isFinished else { return nil }

            do {
                // Read a chunk from the stream (using default chunk size)
                let data = try await stream.readAsync(upToCount: CHUNK_SIZE_BYTES)

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
                throw NIOHTTPClientError.streamingError(error)
            }
        }
    }
}
