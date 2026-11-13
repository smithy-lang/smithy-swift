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

/// Utilities used by the tests that are code-generated from the Smithy `eventStreamTests` trait.
///
/// See https://smithy.io/2.0/additional-specs/protocol-traits.html#eventstreamtests-trait
public enum EventStreamTestUtil {

    /// The media type used for event stream HTTP bodies.
    public static let eventStreamMediaType = "application/vnd.amazon.eventstream"

    /// The header that carries the signature on a signed event stream message.
    static let chunkSignatureHeaderName = ":chunk-signature"

    // MARK: - Requests

    /// Creates an event stream that yields the passed events, then finishes.
    /// - Parameter events: The events to be yielded on the stream.
    /// - Returns: A stream of the passed events.
    public static func stream<Event: Sendable>(_ events: [Event]) -> AsyncThrowingStream<Event, any Error> {
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
    public static func stream<Event: Sendable>(
        _ events: [Event],
        finishingWith error: (any Error)?
    ) -> AsyncThrowingStream<Event, any Error> {
        AsyncThrowingStream { continuation in
            events.forEach { continuation.yield($0) }
            continuation.finish(throwing: error)
        }
    }

    /// Performs an operation that sends its request to a `ProtocolTestClient`, and returns the request that
    /// was sent.
    ///
    /// The `ProtocolTestClient` throws a `TestCheckError` containing the request instead of sending it.
    /// That request is caught & returned.  Any other error thrown by the operation is rethrown.
    /// - Parameter operation: A closure that performs the operation.
    /// - Returns: The HTTP request that the operation sent.
    public static func captureRequest(_ operation: () async throws -> Void) async throws -> HTTPRequest {
        do {
            try await operation()
        } catch TestCheckError.actual(let request) {
            return request
        }
        throw SmithyTestUtilError("Operation completed without sending a request to the protocol test client")
    }

    /// Reads the HTTP body of the passed request to its end, and decodes it into event stream messages.
    ///
    /// See ``messages(from:)`` for how the messages are processed after decoding.
    /// - Parameter request: The request containing the event stream body.
    /// - Returns: The event stream messages that were sent in the request body.
    public static func messages(in request: HTTPRequest) async throws -> [Message] {
        let data = try await request.body.readData() ?? Data()
        return try messages(from: data)
    }

    /// Decodes event stream messages from binary data.
    ///
    /// If messages are signed, each signed message is unwrapped & the message it contains is returned
    /// in its place.  The empty message that terminates an event stream is removed.
    /// - Parameter data: The binary data containing zero or more encoded event stream messages.
    /// - Returns: The decoded event stream messages.
    public static func messages(from data: Data) throws -> [Message] {
        try decode(data).compactMap(unwrap(_:))
    }

    private static func decode(_ data: Data) throws -> [Message] {
        let decoder = DefaultMessageDecoder()
        try decoder.feed(data: data)
        try decoder.endOfStream()
        var messages = [Message]()
        while let message = try decoder.message() {
            messages.append(message)
        }
        return messages
    }

    private static func unwrap(_ message: Message) throws -> Message? {
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

    // MARK: - Responses

    /// Encodes messages to binary data in the event stream format.
    /// - Parameter messages: The messages to be encoded.
    /// - Returns: The binary data for the encoded messages, in order.
    public static func encode(_ messages: [Message]) throws -> Data {
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
    public static func httpResponse(statusCode: Int, headers: [String: String], body: Data) -> HTTPResponse {
        HTTPResponse(
            headers: Headers(headers),
            body: .stream(BufferedStream(data: body, isClosed: true)),
            statusCode: HTTPStatusCode(rawValue: statusCode) ?? .badRequest
        )
    }

    /// Reads all events from an event stream until it ends.
    ///
    /// Any error thrown by the stream is rethrown.
    /// - Parameter stream: The stream to be read.  If `nil`, an empty array is returned.
    /// - Returns: The events that were read from the stream, in order.
    public static func events<Event>(_ stream: AsyncThrowingStream<Event, any Error>?) async throws -> [Event] {
        guard let stream else { return [] }
        var events = [Event]()
        for try await event in stream {
            events.append(event)
        }
        return events
    }

    // MARK: - Payload comparison

    /// Compares an event payload to the expected payload, using the passed media type to determine how
    /// the payloads are compared.
    ///
    /// JSON, CBOR, and XML payloads are compared structurally.  All other payloads are compared byte-for-byte.
    /// - Parameters:
    ///   - actual: The payload that was sent or received.
    ///   - expected: The payload that was expected.
    ///   - mediaType: The media type of the payload, if any.
    /// - Returns: `true` if the payloads match, `false` otherwise.
    public static func payload(_ actual: Data, matches expected: Data, mediaType: String?) throws -> Bool {
        let mediaType = mediaType?.lowercased() ?? ""
        if mediaType.hasSuffix("json") {
            return try JSONComparator.jsonData(actual, isEqualTo: expected)
        } else if mediaType.hasSuffix("cbor") {
            return try CBORComparator.cborData(actual, isEqualTo: expected)
        } else if mediaType.hasSuffix("xml") {
            return XMLComparator.xmlData(actual, isEqualTo: expected)
        } else {
            return actual == expected
        }
    }

    // MARK: - HTTP request comparison

    /// Determines whether the request includes the passed query item.
    /// - Parameters:
    ///   - request: The request to be checked.
    ///   - queryItem: The query item, in `name=value` or `name` form, as given in the Smithy protocol test.
    /// - Returns: `true` if the query item is present, `false` otherwise.
    public static func request(_ request: HTTPRequest, hasQueryItem queryItem: String) -> Bool {
        let (name, value) = split(queryItem)
        return (request.queryItems ?? []).contains { $0.name == name && $0.value == value }
    }

    /// Determines whether the request includes a query item with the passed name.
    /// - Parameters:
    ///   - request: The request to be checked.
    ///   - name: The name of the query item.
    /// - Returns: `true` if a query item with the name is present, `false` otherwise.
    public static func request(_ request: HTTPRequest, hasQueryItemNamed name: String) -> Bool {
        (request.queryItems ?? []).contains { $0.name == name }
    }

    private static func split(_ queryItem: String) -> (String, String?) {
        let components = queryItem.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        let name = String(components[0])
        guard components.count > 1 else { return (name, nil) }
        return (name, String(components[1]))
    }
}
