//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyEventStreamsAPI
import SmithyEventStreamsAuthAPI
import struct Foundation.Data

// Code left indented to prevent Git diff from being blown up by whitespace changes.
// Will fix after event stream modularizaion has been reviewed.

    /// Stream adapter that encodes input into `Data` objects.
    public class DefaultMessageEncoderStream<Event>: @unchecked Sendable, MessageEncoderStream, Stream {

        let stream: AsyncThrowingStream<Event, Error>
        let messageEncoder: MessageEncoder
        let messageSigner: MessageSigner
        let marshalClosure: MarshalClosure<Event>
        var readAsyncIterator: AsyncIterator?
        let initialRequestMessage: Message?

        public required init(
            stream: AsyncThrowingStream<Event, Error>,
            messageEncoder: MessageEncoder,
            marshalClosure: @escaping MarshalClosure<Event>,
            messageSigner: MessageSigner,
            initialRequestMessage: Message? = nil
        ) {
            self.stream = stream
            self.messageEncoder = messageEncoder
            self.messageSigner = messageSigner
            self.marshalClosure = marshalClosure
            self.initialRequestMessage = initialRequestMessage
            self.readAsyncIterator = makeAsyncIterator()
        }

        public struct AsyncIterator: AsyncIteratorProtocol {
            let stream: AsyncThrowingStream<Event, Error>
            let messageEncoder: MessageEncoder
            var messageSigner: MessageSigner
            let marshalClosure: MarshalClosure<Event>
            let initialRequestMessage: Message?

            private var lastMessageSent: Bool = false
            private var streamIterator: AsyncThrowingStream<Event, Error>.Iterator
            private var sentInitialRequest: Bool = false

            init(
                stream: AsyncThrowingStream<Event, Error>,
                messageEncoder: MessageEncoder,
                marshalClosure: @escaping MarshalClosure<Event>,
                messageSigner: MessageSigner,
                initialRequestMessage: Message? = nil
            ) {
                self.stream = stream
                self.streamIterator = stream.makeAsyncIterator()
                self.messageEncoder = messageEncoder
                self.messageSigner = messageSigner
                self.marshalClosure = marshalClosure
                self.initialRequestMessage = initialRequestMessage
            }

            mutating public func next() async throws -> Data? {
                if let initialRequestMessage, !sentInitialRequest {
                    sentInitialRequest = true
                    let signedMessage = try await messageSigner.sign(message: initialRequestMessage)
                    return try messageEncoder.encode(message: signedMessage)
                } else {
                    guard let event = try await streamIterator.next() else {
                        // There are no more messages in the base stream
                        // if we have not sent the last message, send it now
                        guard lastMessageSent else {
                            let emptySignedMessage = try await messageSigner.signEmpty()
                            let data = try messageEncoder.encode(message: emptySignedMessage)
                            lastMessageSent = true
                            return data
                        }
                        // mark the stream as complete
                        return nil
                    }
                    return try await processEventToData(event: event)
                }
            }

            mutating func processEventToData(event: Event) async throws -> Data {
                // marshall event to message
                let message = try marshalClosure(event)
                // sign the message
                let signedMessage = try await messageSigner.sign(message: message)
                // encode again the signed message then return
                return try messageEncoder.encode(message: signedMessage)
            }
        }

        public func makeAsyncIterator() -> AsyncIterator {
            AsyncIterator(
                stream: stream,
                messageEncoder: messageEncoder,
                marshalClosure: marshalClosure,
                messageSigner: messageSigner,
                initialRequestMessage: initialRequestMessage
            )
        }

        // MARK: Stream

        /// Returns the current position in the stream
        public var position: Data.Index = 0

        /// Returns nil because the length of async stream is not known
        public var length: Int?

        /// Returns false because the length of async stream is not known
        /// and therefore cannot be empty
        public var isEmpty: Bool = false

        /// Returns false because async stream is not seekable
        public var isSeekable: Bool = false

        /// Internal buffer to store excess data read from async stream
        var buffer = Data()

        public func read(upToCount count: Int) throws -> Data? {
            fatalError("read(upToCount:) is not supported by AsyncStream backed streams")
        }

        public func readToEnd() throws -> Data? {
            fatalError("readToEnd() is not supported by AsyncStream backed streams")
        }

        public func readToEndAsync() async throws -> Data? {
            var data = Data()
            while let moreData = try await readAsync(upToCount: Int.max) {
                data.append(moreData)
            }
            return data
        }

        /// Reads up to `count` bytes from the stream asynchronously
        /// - Parameter count: maximum number of bytes to read
        /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available
        public func readAsync(upToCount count: Int) async throws -> Data? {
            var data = Data()
            var remaining = count

            // read from buffer
            if !buffer.isEmpty {
                let toRead = Swift.min(remaining, buffer.count)
                data.append(buffer.subdata(in: 0..<toRead))

                // reset buffer to remaining data
                buffer = Data(buffer.subdata(in: toRead..<buffer.count))

                // update remaining bytes to read
                remaining -= toRead

                // update position
                position = position.advanced(by: toRead)
            }

            while remaining > 0, let next = try await readAsyncIterator?.next() {
                // read from async stream
                let toRead = Swift.min(remaining, next.count)
                data.append(next[0..<toRead])
                remaining -= toRead

                // update position
                position += toRead

                // if we have more data, add it to the buffer
                if next.count > toRead {
                    buffer.append(next[toRead..<next.count])
                }
            }

            // async stream has ended, return nil to mark stream end
            if data.isEmpty {
                return nil
            }

            return data
        }

        public func write(contentsOf data: Data) throws {
            fatalError("write(contentsOf:) is not supported by AsyncStream backed streams")
        }

        /// Closing the stream is a no-op because the underlying async stream is not owned by this stream
        public func close() {
            // no-op
        }

        public func closeWithError(_ error: Error) {
            // no-op
        }
    }
