//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import enum Smithy.ByteStream
@_spi(SmithyEventStreams) import class SmithyEventStreams.DefaultMessageDecoder
@_spi(SmithyEventStreams) import struct SmithyEventStreams.DefaultMessageEncoder
import struct SmithyEventStreamsAPI.Message
import struct SmithyHTTPAPI.Headers
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse
import enum SmithyHTTPAPI.HTTPStatusCode
import class SmithyStreams.BufferedStream

/// Helpers for the Swift Testing tests that are code-generated from the Smithy `eventStreamTests` trait.
///
/// An event stream test both sends a request & receives a response, so this protocol includes the
/// request & response test helpers as well.
///
/// See https://smithy.io/2.0/additional-specs/protocol-traits.html#eventstreamtests-trait
public protocol EventStreamProtocolTestSuite: HTTPRequestProtocolTestSuite, HTTPResponseProtocolTestSuite {}

public extension EventStreamProtocolTestSuite {

    // MARK: - Requests

    /// Creates an event stream that yields the passed events, then finishes.
    /// - Parameter events: The events to be yielded on the stream.
    /// - Returns: A stream of the passed events.
    func stream<Event: Sendable>(_ events: [Event]) -> AsyncThrowingStream<Event, any Error> {
        stream(events, finishingWith: nil)
    }

    /// Creates an event stream that yields the passed events, then finishes by throwing the passed error.
    ///
    /// A modeled error on an event stream is not an event in Swift; a client sends it by finishing the
    /// event stream with that error.
    /// - Parameters:
    ///   - events: The events to be yielded on the stream.
    ///   - error: The error to be thrown when the stream finishes, or `nil` to finish normally.
    /// - Returns: A stream of the passed events.
    func stream<Event: Sendable>(
        _ events: [Event],
        finishingWith error: (any Error)?
    ) -> AsyncThrowingStream<Event, any Error> {
        AsyncThrowingStream { continuation in
            events.forEach { continuation.yield($0) }
            continuation.finish(throwing: error)
        }
    }

    /// Reads the HTTP body of the passed request to its end, and decodes it into event stream messages.
    ///
    /// See ``messages(from:)`` for how the messages are processed after decoding.
    /// - Parameter request: The request containing the event stream body.
    /// - Returns: The event stream messages that were sent in the request body.
    func messages(in request: HTTPRequest) async throws -> [Message] {
        let data = try await request.body.readData() ?? Data()
        return try messages(from: data)
    }

    /// Decodes event stream messages from binary data.
    ///
    /// If messages are signed, each signed message is unwrapped & the message it contains is returned
    /// in its place.  The empty message that terminates an event stream is removed.
    /// - Parameter data: The binary data containing zero or more encoded event stream messages.
    /// - Returns: The decoded event stream messages.
    func messages(from data: Data) throws -> [Message] {
        try EventStreamMessageDecoding.decode(data).compactMap(EventStreamMessageDecoding.unwrap(_:))
    }

    // MARK: - Responses

    /// Encodes messages to binary data in the event stream format.
    /// - Parameter messages: The messages to be encoded.
    /// - Returns: The binary data for the encoded messages, in order.
    func encode(_ messages: [Message]) throws -> Data {
        let encoder = DefaultMessageEncoder()
        return try messages.reduce(into: Data()) { data, message in
            data.append(try encoder.encode(message: message))
        }
    }

    /// Creates a HTTP response with a streaming body, for use as the response to an event stream operation.
    /// - Parameters:
    ///   - statusCode: The HTTP status code for the response.
    ///   - headers: The HTTP headers for the response.
    ///   - body: The binary data to be streamed as the body of the response.
    /// - Returns: The HTTP response.
    /// - Throws: `SmithyTestUtilError` if the status code is not one that `HTTPStatusCode` defines.
    func httpResponse(statusCode: Int, headers: [String: String], body: Data) throws -> HTTPResponse {
        guard let httpStatusCode = HTTPStatusCode(rawValue: statusCode) else {
            throw SmithyTestUtilError("HTTP status code \(statusCode) is not defined by HTTPStatusCode")
        }
        return HTTPResponse(
            headers: Headers(headers),
            body: .stream(BufferedStream(data: body, isClosed: true)),
            statusCode: httpStatusCode
        )
    }

    /// Reads all events from an event stream until it ends.
    ///
    /// Any error thrown by the stream is rethrown.
    /// - Parameter stream: The stream to be read.  If `nil`, an empty array is returned.
    /// - Returns: The events that were read from the stream, in order.
    func events<Event>(_ stream: AsyncThrowingStream<Event, any Error>?) async throws -> [Event] {
        guard let stream else { return [] }
        var events = [Event]()
        for try await event in stream {
            events.append(event)
        }
        return events
    }

    // MARK: - Expected failures

    /// Runs code that is expected to fail with an error thrown by the SDK, and returns that error.
    ///
    /// Errors thrown by the test harness itself (`SmithyTestUtilError`), e.g. when the operation did not
    /// send a request to the protocol test client, are rethrown so that the test fails, rather than being
    /// mistaken for the expected failure.
    /// - Parameter body: The code that is expected to throw.
    /// - Returns: The error thrown by `body`, or `nil` if `body` did not throw.
    func sdkError(from body: () async throws -> Void) async throws -> (any Error)? {
        do {
            try await body()
            return nil
        } catch let error as SmithyTestUtilError {
            throw error
        } catch {
            return error
        }
    }

    // MARK: - Payload comparison

    /// Compares an event payload to the expected payload, using the passed media type to determine how
    /// the payloads are compared.
    ///
    /// Payloads are compared the same way as HTTP bodies in request tests: JSON, CBOR, XML, and form URL
    /// payloads are compared structurally, and all other payloads are compared byte-for-byte.
    /// - Parameters:
    ///   - actual: The payload that was sent or received.
    ///   - expected: The payload that was expected.
    ///   - mediaType: The media type of the payload, if any.
    /// - Returns: `true` if the payloads match, `false` otherwise.
    func payload(_ actual: Data, matches expected: Data, mediaType: String?) throws -> Bool {
        let contentType = HTTPBodyContentType(mediaType: mediaType)
        return try HTTPRequestTestSupport.bodyData(actual, matches: expected, contentType: contentType)
    }
}

/// Decodes event stream messages, unwrapping signed messages.
enum EventStreamMessageDecoding {

    /// The header that carries the signature on a signed event stream message.
    static let chunkSignatureHeaderName = ":chunk-signature"

    static func decode(_ data: Data) throws -> [Message] {
        let decoder = DefaultMessageDecoder()
        try decoder.feed(data: data)
        try decoder.endOfStream()
        var messages = [Message]()
        while let message = try decoder.message() {
            messages.append(message)
        }
        return messages
    }

    static func unwrap(_ message: Message) throws -> Message? {
        if message.headers.value(name: chunkSignatureHeaderName) != nil {
            // This is a signed message.  Its payload is the encoded message that was signed;
            // an empty payload marks the end of the stream.
            guard !message.payload.isEmpty else { return nil }
            let innerMessages = try decode(message.payload)
            guard innerMessages.count == 1 else {
                throw SmithyTestUtilError("Signed message contained \(innerMessages.count) messages, expected 1")
            }
            return try unwrap(innerMessages[0])
        } else if message.headers.isEmpty && message.payload.isEmpty {
            // An empty, unsigned message marks the end of the stream.
            return nil
        } else {
            return message
        }
    }
}
