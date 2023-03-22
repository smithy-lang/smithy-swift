//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension EventStream {
    /// Stream adapter that encodes input into `Data` objects.
    public class DefaultMessageEncoderStream<Event: MessageMarshallable>: MessageEncoderStream, Stream {
        let stream: AsyncThrowingStream<Event, Error>
        let messageEncoder: MessageEncoder
        let messageSinger: MessageSigner
        let requestEncoder: RequestEncoder
        var readAsyncIterator: AsyncIterator? = nil

        public init(stream: AsyncThrowingStream<Event, Error>,
                    messageEncoder: MessageEncoder,
                    requestEncoder: RequestEncoder,
                    messageSinger: MessageSigner) {
            self.stream = stream
            self.messageEncoder = messageEncoder
            self.messageSinger = messageSinger
            self.requestEncoder = requestEncoder
            self.readAsyncIterator = makeAsyncIterator()
        }

        public struct AsyncIterator: AsyncIteratorProtocol {
            let stream: AsyncThrowingStream<Event, Error>
            let messageEncoder: MessageEncoder
            var messageSinger: MessageSigner
            let requestEncoder: RequestEncoder

            private var lastMessageSent: Bool = false

            init(stream: AsyncThrowingStream<Event, Error>,
                 messageEncoder: MessageEncoder,
                 requestEncoder: RequestEncoder,
                 messageSinger: MessageSigner) {
                self.stream = stream
                self.messageEncoder = messageEncoder
                self.messageSinger = messageSinger
                self.requestEncoder = requestEncoder
            }

            mutating public func next() async throws -> Data? {
                var iterator = stream.makeAsyncIterator()
                guard let event = try await iterator.next() else {
                    // There are no more messages in the base stream
                    // if we have not sent the last message, send it now
                    guard lastMessageSent else {
                        let emptySignedMessage = try await messageSinger.signEmpty()
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
                let signedMessage = try await messageSinger.sign(message: message)

                // encode again the signed message
                let data = try messageEncoder.encode(message: signedMessage)
                return data
            }
        }

        public func makeAsyncIterator() -> AsyncIterator {
            AsyncIterator(stream: stream,
                          messageEncoder: messageEncoder,
                          requestEncoder: requestEncoder,
                          messageSinger: messageSinger)
        }

        // MARK: Stream

        public var position: ClientRuntime.Data.Index = 0

        public var length: Int?

        public var isEmpty: Bool = false

        public var isSeekable: Bool = false

        var buffer = Data()

        public func read(upToCount count: Int) throws -> ClientRuntime.Data? {
            fatalError("read(upToCount:) is not supported by AsyncStream backed streams")
        }

        public func readToEnd() throws -> ClientRuntime.Data? {
            fatalError("readToEnd() is not supported by AsyncStream backed streams")
        }

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

        public func close() throws {
            // no-op
        }
    }
}
