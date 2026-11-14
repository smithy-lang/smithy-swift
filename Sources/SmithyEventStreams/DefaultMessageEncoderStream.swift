//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import Smithy
import SmithyEventStreamsAPI
import SmithyEventStreamsAuthAPI

/// Stream adapter that encodes input into `Data` objects.
@_spi(SmithyEventStreams)
public class DefaultMessageEncoderStream<Event>: MessageEncoderStream, Stream, @unchecked Sendable {

    let stream: AsyncThrowingStream<Event, Error>
    let messageEncoder: MessageEncoder
    let messageSigner: MessageSigner
    let marshalClosure: MarshalClosure<Event>
    let errorMarshalClosure: ErrorMarshalClosure?
    var readAsyncIterator: AsyncIterator?
    let initialRequestMessage: Message?

    /// A closure that marshals an error thrown by the event stream to an exception message.
    ///
    /// The closure returns `nil` if the error is not a modeled error on the event stream.
    public typealias ErrorMarshalClosure = (any Error) throws -> Message?

    /// Creates a stream that encodes events to `Data`.
    /// - Parameters:
    ///   - stream: The stream of events to be encoded.
    ///   - messageEncoder: The encoder used to encode each message.
    ///   - marshalClosure: A closure that marshals each event to a message.
    ///   - messageSigner: The signer used to sign each message.
    ///   - initialRequestMessage: A message to be sent before any events, if any.
    public required convenience init(
        stream: AsyncThrowingStream<Event, Error>,
        messageEncoder: MessageEncoder,
        marshalClosure: @escaping MarshalClosure<Event>,
        messageSigner: MessageSigner,
        initialRequestMessage: Message? = nil
    ) {
        self.init(
            stream: stream,
            messageEncoder: messageEncoder,
            marshalClosure: marshalClosure,
            errorMarshalClosure: nil,
            messageSigner: messageSigner,
            initialRequestMessage: initialRequestMessage
        )
    }

    /// Creates a stream that encodes events to `Data`, and that sends modeled errors thrown by the
    /// event stream as exception messages.
    /// - Parameters:
    ///   - stream: The stream of events to be encoded.
    ///   - messageEncoder: The encoder used to encode each message.
    ///   - marshalClosure: A closure that marshals each event to a message.
    ///   - errorMarshalClosure: A closure that marshals an error thrown by `stream` to an exception message.
    ///     If the closure returns a message, that message is sent and the stream then ends normally.
    ///     If the closure is `nil` or returns `nil`, the error is rethrown.
    ///   - messageSigner: The signer used to sign each message.
    ///   - initialRequestMessage: A message to be sent before any events, if any.
    public init(
        stream: AsyncThrowingStream<Event, Error>,
        messageEncoder: MessageEncoder,
        marshalClosure: @escaping MarshalClosure<Event>,
        errorMarshalClosure: ErrorMarshalClosure?,
        messageSigner: MessageSigner,
        initialRequestMessage: Message? = nil
    ) {
        self.stream = stream
        self.messageEncoder = messageEncoder
        self.messageSigner = messageSigner
        self.marshalClosure = marshalClosure
        self.errorMarshalClosure = errorMarshalClosure
        self.initialRequestMessage = initialRequestMessage
        self.readAsyncIterator = makeAsyncIterator()
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        let stream: AsyncThrowingStream<Event, Error>
        let messageEncoder: MessageEncoder
        var messageSigner: MessageSigner
        let marshalClosure: MarshalClosure<Event>
        let errorMarshalClosure: ErrorMarshalClosure?
        let initialRequestMessage: Message?

        private var lastMessageSent: Bool = false
        private var baseStreamThrewError: Bool = false
        private var pendingErrorMessage: Message?
        private var streamIterator: AsyncThrowingStream<Event, Error>.Iterator
        private var sentInitialRequest: Bool = false

        init(
            stream: AsyncThrowingStream<Event, Error>,
            messageEncoder: MessageEncoder,
            marshalClosure: @escaping MarshalClosure<Event>,
            errorMarshalClosure: ErrorMarshalClosure? = nil,
            messageSigner: MessageSigner,
            initialRequestMessage: Message? = nil
        ) {
            self.stream = stream
            self.streamIterator = stream.makeAsyncIterator()
            self.messageEncoder = messageEncoder
            self.messageSigner = messageSigner
            self.marshalClosure = marshalClosure
            self.errorMarshalClosure = errorMarshalClosure
            self.initialRequestMessage = initialRequestMessage
        }

        mutating public func next() async throws -> Data? {
            if let initialRequestMessage, !sentInitialRequest {
                sentInitialRequest = true
                let signedMessage = try await messageSigner.sign(message: initialRequestMessage)
                return try messageEncoder.encode(message: signedMessage)
            } else {
                guard let event = try await nextEvent() else {
                    // If the base stream ended by throwing a modeled error, send it as an exception message
                    if let errorMessage = pendingErrorMessage {
                        pendingErrorMessage = nil
                        let signedMessage = try await messageSigner.sign(message: errorMessage)
                        return try messageEncoder.encode(message: signedMessage)
                    }
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

        /// Returns the next event from the base stream, or `nil` if the base stream has ended.
        ///
        /// If the base stream throws a modeled error, the error is sent as an exception message,
        /// and the base stream is treated as ended after that.
        private mutating func nextEvent() async throws -> Event? {
            // A stream that has thrown has ended; don't read from it again.
            guard !baseStreamThrewError else { return nil }
            do {
                return try await streamIterator.next()
            } catch {
                guard let errorMessage = try errorMarshalClosure?(error) else { throw error }
                baseStreamThrewError = true
                pendingErrorMessage = errorMessage
                return nil
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
            errorMarshalClosure: errorMarshalClosure,
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
        throw UnsupportedStreamOperationError(operation: "read(upToCount:)")
    }

    public func readToEnd() throws -> Data? {
        throw UnsupportedStreamOperationError(operation: "readToEnd()")
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
        throw UnsupportedStreamOperationError(operation: "write(contentsOf:)")
    }

    /// Closing the stream is a no-op because the underlying async stream is not owned by this stream
    public func close() {
        // no-op
    }

    public func closeWithError(_ error: Error) {
        // no-op
    }
}

/// Thrown when a synchronous read or a write is attempted on a stream backed by an `AsyncStream`.
///
/// Such a stream can only be read asynchronously.  This error is thrown, rather than stopping the process, so
/// that a caller that attempts a synchronous read (i.e. to compute a hash of the body) fails gracefully.
struct UnsupportedStreamOperationError: Error, CustomStringConvertible {
    let operation: String

    var description: String {
        "\(operation) is not supported by AsyncStream backed streams"
    }
}
