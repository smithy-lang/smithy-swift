//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension EventStream {

    /// Stream adapter that decodes input data into `EventStream.Message` objects.
    public struct DefaultMessageDecoderStream<Event>: MessageDecoderStream {
        public typealias Element = Event

        let stream: Stream
        let messageDecoder: MessageDecoder
        let unmarshalClosure: UnmarshalClosure<Event>

        public init(stream: Stream, messageDecoder: MessageDecoder, unmarshalClosure: @escaping UnmarshalClosure<Event>) {
            self.stream = stream
            self.messageDecoder = messageDecoder
            self.unmarshalClosure = unmarshalClosure
        }

        public struct AsyncIterator: AsyncIteratorProtocol {
            let stream: Stream
            let messageDecoder: MessageDecoder
            let unmarshalClosure: UnmarshalClosure<Event>

            init(stream: Stream, messageDecoder: MessageDecoder, unmarshalClosure: @escaping UnmarshalClosure<Event>) {
                self.stream = stream
                self.messageDecoder = messageDecoder
                self.unmarshalClosure = unmarshalClosure
            }

            mutating public func next() async throws -> Event? {
                var data: Data?
                // read until the end of the stream, starting with data already in the buffer, if any
                repeat {
                    // feed the data to the decoder
                    // this may result in a message being returned
                    try messageDecoder.feed(data: data ?? Data())

                    // if we have a message in the decoder buffer, return it
                    if let message = try messageDecoder.message() {
                        return try unmarshalClosure(message)
                    }

                    data = try await stream.readAsync(upToCount: Int.max)
                // nil data from stream indicates stream has closed, so stop reading it & stop async iterating
                } while data != nil

                // this is the end of the stream
                // notify the decoder that the stream has ended
                try messageDecoder.endOfStream()
                return nil
            }
        }

        public func makeAsyncIterator() -> AsyncIterator {
            AsyncIterator(
                stream: stream,
                messageDecoder: messageDecoder,
                unmarshalClosure: unmarshalClosure
            )
        }
    }
}
