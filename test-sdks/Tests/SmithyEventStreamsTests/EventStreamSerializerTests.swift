//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import struct Foundation.Data
import struct Foundation.Date
@_spi(SchemaBasedSerde)
@_spi(SmithyEventStreams)
import SmithyEventStreams
import enum SmithyEventStreamsAPI.HeaderValue
import struct SmithyEventStreamsAPI.Message
import protocol SmithyEventStreamsAuthAPI.MessageSigner
@_spi(SchemaBasedSerde)
import SmithyAWSJSON
@_spi(SchemaBasedSerde)
import SmithySerialization
@_spi(SchemaBasedSerde)
import EventStreamTestSDK

/// Tests that the event stream serializers marshal an event stream union to the message
/// format described at https://smithy.io/2.0/spec/streaming.html#event-message-serialization
final class EventStreamSerializerTests: XCTestCase {
    typealias TestStream = EventStreamClientTypes.TestEventStream

    // MARK: - @eventPayload bound members

    func test_marshal_writesABlobPayloadAsOctetStream() async throws {
        let data = Data("abcdefg".utf8)
        let event = TestStream.messagewithblob(.init(data: data))

        let message = try await marshal(event)

        XCTAssertEqual(headers(of: message), [
            ":message-type": .string("event"),
            ":event-type": .string("MessageWithBlob"),
            ":content-type": .string("application/octet-stream"),
        ])
        XCTAssertEqual(message.payload, data)
    }

    func test_marshal_writesAStringPayloadAsTextPlain() async throws {
        let event = TestStream.messagewithstring(.init(data: "abcdefg"))

        let message = try await marshal(event)

        XCTAssertEqual(headers(of: message), [
            ":message-type": .string("event"),
            ":event-type": .string("MessageWithString"),
            ":content-type": .string("text/plain"),
        ])
        XCTAssertEqual(message.payload, Data("abcdefg".utf8))
    }

    func test_marshal_writesAStructPayloadUsingTheCodec() async throws {
        let event = TestStream.messagewithstruct(.init(
            someStruct: .init(someInt: 5, someString: "abc")
        ))

        let message = try await marshal(event)

        XCTAssertEqual(headers(of: message), [
            ":message-type": .string("event"),
            ":event-type": .string("MessageWithStruct"),
            ":content-type": .string("application/json"),
        ])
        XCTAssertEqual(try json(message), #"{"someInt":5,"someString":"abc"}"#)
    }

    func test_marshal_writesAUnionPayloadUsingTheCodec() async throws {
        let event = TestStream.messagewithunion(.init(someUnion: .foo("abc")))

        let message = try await marshal(event)

        XCTAssertEqual(headers(of: message), [
            ":message-type": .string("event"),
            ":event-type": .string("MessageWithUnion"),
            ":content-type": .string("application/json"),
        ])
        XCTAssertEqual(try json(message), #"{"foo":"abc"}"#)
    }

    // MARK: - @eventHeader bound members

    func test_marshal_writesEveryHeaderType() async throws {
        let date = Date(timeIntervalSince1970: 1_733_000_000)
        let event = TestStream.messagewithheaders(.init(
            blob: Data("xyz".utf8),
            boolean: true,
            byte: 7,
            int: 100_000,
            long: 5_000_000_000,
            short: 300,
            string: "abc",
            timestamp: date
        ))

        let message = try await marshal(event)

        XCTAssertEqual(headers(of: message), [
            ":message-type": .string("event"),
            ":event-type": .string("MessageWithHeaders"),
            "blob": .byteArray(Data("xyz".utf8)),
            "boolean": .bool(true),
            "byte": .byte(7),
            "int": .int32(100_000),
            "long": .int64(5_000_000_000),
            "short": .int16(300),
            "string": .string("abc"),
            "timestamp": .timestamp(date),
        ])

        // An event with only header-bound members has no payload, and so no content type.
        XCTAssertEqual(message.payload, Data())
    }

    func test_marshal_omitsNilHeaders() async throws {
        let event = TestStream.messagewithheaders(.init(string: "abc"))

        let message = try await marshal(event)

        XCTAssertEqual(headers(of: message), [
            ":message-type": .string("event"),
            ":event-type": .string("MessageWithHeaders"),
            "string": .string("abc"),
        ])
    }

    func test_marshal_writesBothAHeaderAndAPayload() async throws {
        let payload = Data("abcdefg".utf8)
        let event = TestStream.messagewithheaderandpayload(.init(
            header: "header-value",
            payload: payload
        ))

        let message = try await marshal(event)

        XCTAssertEqual(headers(of: message), [
            ":message-type": .string("event"),
            ":event-type": .string("MessageWithHeaderAndPayload"),
            "header": .string("header-value"),
            ":content-type": .string("application/octet-stream"),
        ])
        XCTAssertEqual(message.payload, payload)
    }

    // MARK: - unbound members

    func test_marshal_writesUnboundMembersToThePayload() async throws {
        let event = TestStream.messagewithnoheaderpayloadtraits(.init(
            someInt: 5,
            someString: "abc"
        ))

        let message = try await marshal(event)

        XCTAssertEqual(headers(of: message), [
            ":message-type": .string("event"),
            ":event-type": .string("MessageWithNoHeaderPayloadTraits"),
            ":content-type": .string("application/json"),
        ])
        XCTAssertEqual(try json(message), #"{"someInt":5,"someString":"abc"}"#)
    }

    func test_marshal_writesUnboundMembersToThePayloadAndOmitsHeaderBoundMembers() async throws {
        let event = TestStream.messagewithunboundpayloadtraits(.init(
            header: "header-value",
            unboundString: "abc"
        ))

        let message = try await marshal(event)

        XCTAssertEqual(headers(of: message), [
            ":message-type": .string("event"),
            ":event-type": .string("MessageWithUnboundPayloadTraits"),
            "header": .string("header-value"),
            ":content-type": .string("application/json"),
        ])

        // The header-bound member must not be duplicated into the payload.
        XCTAssertEqual(try json(message), #"{"unboundString":"abc"}"#)
    }

    func test_marshal_writesAnEmptyPayloadForAnEventWithNoMembers() async throws {
        let event = TestStream.messagewithnomembers(.init())

        let message = try await marshal(event)

        XCTAssertEqual(headers(of: message), [
            ":message-type": .string("event"),
            ":event-type": .string("MessageWithNoMembers"),
        ])
        XCTAssertEqual(message.payload, Data())
    }

    // MARK: - sdkUnknown

    func test_marshal_throwsForTheUnknownEventType() async throws {
        let event = TestStream.sdkUnknown("unknown-event")

        do {
            _ = try await marshal(event)
            XCTFail("Expected an error when serializing the unknown event type")
        } catch {
            // expected
        }
    }

    // MARK: - Test helpers

    /// Serializes an input carrying a single-event stream, then decodes the request body
    /// back into the message that was sent for that event.
    private func marshal(_ event: TestStream) async throws -> Message {
        let input = EventStreamOperationInput(eventStream: stream(of: event))
        let subject = EventStreamSerializer(
            codec: SmithyAWSJSON.HTTPClientProtocol(version: .v1_0).codec,
            contentType: "application/json",
            messageEncoder: DefaultMessageEncoder(),
            messageSigner: NoOpMessageSigner()
        )

        try input.serialize(subject)

        guard case .stream(let body) = subject.body else {
            throw TestError("Expected the serialized body to be a stream")
        }
        let data = try await body.readToEndAsync() ?? Data()

        // Decode the encoded body back to messages.  The first message is the event that
        // was serialized; the empty message that terminates the stream follows it.
        let decoder = DefaultMessageDecoder()
        try decoder.feed(data: data)
        guard let message = try decoder.message() else {
            throw TestError("No message was decoded from the serialized event stream")
        }
        return message
    }

    private func stream(of event: TestStream) -> AsyncThrowingStream<TestStream, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(event)
            continuation.finish()
        }
    }

    /// The message's headers, keyed by name, for order-independent comparison.
    private func headers(of message: Message) -> [String: HeaderValue] {
        Dictionary(uniqueKeysWithValues: message.headers.map { ($0.name, $0.value) })
    }

    private func json(_ message: Message) throws -> String {
        guard let json = String(data: message.payload, encoding: .utf8) else {
            throw TestError("Message payload is not valid UTF-8")
        }
        return json
    }
}

/// A signer that passes messages through unchanged, so tests observe only what was serialized.
private struct NoOpMessageSigner: MessageSigner {

    func sign(message: Message) async throws -> Message { message }

    func signEmpty() async throws -> Message { Message() }
}

private struct TestError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }
}

