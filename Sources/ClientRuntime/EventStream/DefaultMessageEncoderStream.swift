//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

extension EventStream {
    /// Stream adapter that encodes input into `Data` objects.
    public class DefaultMessageEncoderStream<Event: MessageMarshallable>: MessageEncoderStream, Stream {
        let stream: AsyncThrowingStream<Event, Error>
        let messageEncoder: MessageEncoder
        let messageSigner: MessageSigner
        let requestEncoder: RequestEncoder
        var readAsyncIterator: AsyncIterator?
        let sendInitialRequest: Bool

        public init(
            stream: AsyncThrowingStream<Event, Error>,
            messageEncoder: MessageEncoder,
            requestEncoder: RequestEncoder,
            messageSigner: MessageSigner,
            sendInitialRequest: Bool
        ) {
            self.stream = stream
            self.messageEncoder = messageEncoder
            self.messageSigner = messageSigner
            self.requestEncoder = requestEncoder
            self.sendInitialRequest = sendInitialRequest
            self.readAsyncIterator = makeAsyncIterator()
        }

        public struct AsyncIterator: AsyncIteratorProtocol {
            let stream: AsyncThrowingStream<Event, Error>
            let messageEncoder: MessageEncoder
            var messageSigner: MessageSigner
            let requestEncoder: RequestEncoder
            let sendInitialRequest: Bool

            private var lastMessageSent: Bool = false
            private var streamIterator: AsyncThrowingStream<Event, Error>.Iterator
            private var sentInitialRequest: Bool = false

            init(
                stream: AsyncThrowingStream<Event, Error>,
                messageEncoder: MessageEncoder,
                requestEncoder: RequestEncoder,
                messageSigner: MessageSigner,
                sendInitialRequest: Bool
            ) {
                self.stream = stream
                self.streamIterator = stream.makeAsyncIterator()
                self.messageEncoder = messageEncoder
                self.messageSigner = messageSigner
                self.requestEncoder = requestEncoder
                self.sendInitialRequest = sendInitialRequest
            }

            mutating public func next() async throws -> Data? {
                if (sendInitialRequest && !sentInitialRequest) {
                    sentInitialRequest = true
                    let initialRequestMessage = EventStream.Message(
                        headers: [EventStream.Header(
                            name: ":event-type",
                            value: .string("initial-request")
                        )],
                        // Empty data
                        payload: Data()
                    )
                    return try messageEncoder.encode(
                        message: try await messageSigner.sign(message: initialRequestMessage)
                    )
                }
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

                // marshall event to message
                let message = try event.marshall(encoder: requestEncoder)

                // sign the message
                let signedMessage = try await messageSigner.sign(message: message)

                // encode again the signed message
                let data = try messageEncoder.encode(message: signedMessage)
                return data
            }
        }

        public func makeAsyncIterator() -> AsyncIterator {
            AsyncIterator(
                stream: stream,
                messageEncoder: messageEncoder,
                requestEncoder: requestEncoder,
                messageSigner: messageSigner,
                sendInitialRequest: sendInitialRequest
            )
        }

        // MARK: Stream

        /// Returns the current position in the stream
        public var position: ClientRuntime.Data.Index = 0

        /// Returns nil because the length of async stream is not known
        public var length: Int?

        /// Returns false because the length of async stream is not known
        /// and therefore cannot be empty
        public var isEmpty: Bool = false

        /// Returns false because async stream is not seekable
        public var isSeekable: Bool = false

        /// Internal buffer to store excess data read from async stream
        var buffer = Data()

        public func read(upToCount count: Int) throws -> ClientRuntime.Data? {
            fatalError("read(upToCount:) is not supported by AsyncStream backed streams")
        }

        public func readToEnd() throws -> ClientRuntime.Data? {
            fatalError("readToEnd() is not supported by AsyncStream backed streams")
        }

        public func readToEndAsync() async throws -> ClientRuntime.Data? {
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

        public func write(contentsOf data: ClientRuntime.Data) throws {
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
}
