//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import struct Foundation.Data
@_spi(SchemaBasedSerde)
@_spi(SmithyEventStreams)
import SmithyEventStreams
import struct SmithyEventStreamsAPI.Header
import struct SmithyEventStreamsAPI.Message
@_spi(SchemaBasedSerde)
import SmithyAWSJSON
import class SmithyHTTPAPI.HTTPResponse
import class SmithyStreams.BufferedStream
@_spi(SchemaBasedSerde)
import SmithySerialization
@_spi(SchemaBasedSerde)
import EventStreamTestSDK

/// Tests that the event stream deserializers unmarshal event stream messages, in the format described at
/// https://smithy.io/2.0/spec/streaming.html#event-message-serialization, to an event stream union.
final class EventStreamDeserializerTests: XCTestCase {
    typealias TestStream = EventStreamClientTypes.TestEventStream

    func test_unmarshal_readsABlobPayloadAsRawBytes() async throws {
        let data = Data("abcdefg".utf8)

        let event = try await unmarshal(eventType: "MessageWithBlob", contentType: "application/octet-stream", data)

        guard case .messagewithblob(let value) = event else { return XCTFail("Unexpected event: \(event)") }
        XCTAssertEqual(value.data, data)
    }

    func test_unmarshal_readsAStringPayloadAsUTF8Text() async throws {
        let event = try await unmarshal(eventType: "MessageWithString", contentType: "text/plain", Data("abcdefg".utf8))

        guard case .messagewithstring(let value) = event else { return XCTFail("Unexpected event: \(event)") }
        XCTAssertEqual(value.data, "abcdefg")
    }

    func test_unmarshal_readsAStructPayloadUsingTheCodec() async throws {
        let payload = Data(#"{"someInt":5,"someString":"abc"}"#.utf8)

        let event = try await unmarshal(eventType: "MessageWithStruct", contentType: "application/json", payload)

        guard case .messagewithstruct(let value) = event else { return XCTFail("Unexpected event: \(event)") }
        XCTAssertEqual(value.someStruct?.someInt, 5)
        XCTAssertEqual(value.someStruct?.someString, "abc")
    }

    func test_unmarshal_readsAHeaderAndABlobPayload() async throws {
        let payload = Data([0x00, 0xFF, 0x7B])
        let message = Message(
            headers: [
                Header(name: ":message-type", value: .string("event")),
                Header(name: ":event-type", value: .string("MessageWithHeaderAndPayload")),
                Header(name: ":content-type", value: .string("application/octet-stream")),
                Header(name: "header", value: .string("header-value")),
            ],
            payload: payload
        )

        let event = try await unmarshal(message)

        guard case .messagewithheaderandpayload(let value) = event else { return XCTFail("Unexpected event: \(event)") }
        XCTAssertEqual(value.header, "header-value")
        XCTAssertEqual(value.payload, payload)
    }

    // MARK: - Test helpers

    private func unmarshal(eventType: String, contentType: String, _ payload: Data) async throws -> TestStream {
        try await unmarshal(Message(
            headers: [
                Header(name: ":message-type", value: .string("event")),
                Header(name: ":event-type", value: .string(eventType)),
                Header(name: ":content-type", value: .string(contentType)),
            ],
            payload: payload
        ))
    }

    /// Encodes the message as the body of an event stream response, then deserializes the response
    /// & returns the first event read from the stream.
    private func unmarshal(_ message: Message) async throws -> TestStream {
        let body = try DefaultMessageEncoder().encode(message: message)
        let response = HTTPResponse(
            headers: .init(["Content-Type": "application/vnd.amazon.eventstream"]),
            body: .stream(BufferedStream(data: body, isClosed: true)),
            statusCode: .ok
        )
        let subject = EventStreamDeserializer(
            codec: SmithyAWSJSON.HTTPClientProtocol(version: .v1_0).codec,
            response: response
        )

        let output = try EventStreamOperationOutput.deserialize(subject)

        guard let stream = output.eventStream else { throw TestError("No event stream was deserialized") }
        for try await event in stream {
            return event
        }
        throw TestError("No event was read from the event stream")
    }
}

private struct TestError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }
}
