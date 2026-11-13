//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Testing
import Foundation
@_spi(SmithyEventStreams) import struct SmithyEventStreams.DefaultMessageEncoder
import SmithyEventStreamsAPI
import SmithyTestUtil

@Suite
struct EventStreamTestUtilTests {
    let event = Message(
        headers: [
            Header(name: ":message-type", value: .string("event")),
            Header(name: ":event-type", value: .string("headers")),
            Header(name: "booleanHeader", value: .bool(true)),
        ],
        payload: Data(#"{"a":1}"#.utf8)
    )

    @Test
    func messages_decodesUnsignedMessagesAndDropsTheEmptyEndMessage() throws {
        let data = try EventStreamTestUtil.encode([event, event, Message()])

        let messages = try EventStreamTestUtil.messages(from: data)

        #expect(messages == [event, event])
    }

    @Test
    func messages_unwrapsSignedMessagesAndDropsTheSignedEndMessage() throws {
        let signedEvent = try signedMessage(DefaultMessageEncoder().encode(message: event))
        let signedEnd = signedMessage(Data())
        let data = try EventStreamTestUtil.encode([signedEvent, signedEnd])

        let messages = try EventStreamTestUtil.messages(from: data)

        #expect(messages == [event])
    }

    @Test
    func encode_producesTheSameBytesAsTheSmithyProtocolTest() throws {
        // From the restJson1 event stream protocol test `BooleanHeaderInput`
        let expected = Data(
            base64Encoded: "AAAASwAAADv7Cl8VDTptZXNzYWdlLXR5cGUHAAVldmVudAs6ZXZlbnQtdHlwZQcAB2hlYWRlcnMNYm9vbGVhbkhlYWRlcgC4J9Ws"
        )!
        let message = Message(headers: event.headers)

        #expect(try EventStreamTestUtil.encode([message]) == expected)
    }

    @Test
    func payload_comparesJSONStructurally() throws {
        let actual = Data(#"{"a":1,"b":"c"}"#.utf8)
        let expected = Data(#"{ "b": "c", "a": 1 }"#.utf8)

        #expect(try EventStreamTestUtil.payload(actual, matches: expected, mediaType: "application/json"))
        #expect(try !EventStreamTestUtil.payload(actual, matches: expected, mediaType: "text/plain"))
    }

    @Test
    func payload_comparesOtherMediaTypesByteForByte() throws {
        let data = Data("foo".utf8)

        #expect(try EventStreamTestUtil.payload(data, matches: data, mediaType: "application/octet-stream"))
        #expect(try EventStreamTestUtil.payload(data, matches: data, mediaType: nil))
        #expect(try !EventStreamTestUtil.payload(data, matches: Data("bar".utf8), mediaType: nil))
    }

    @Test
    func events_readsAllEventsFromTheStream() async throws {
        let stream = EventStreamTestUtil.stream([1, 2, 3])

        #expect(try await EventStreamTestUtil.events(stream) == [1, 2, 3])
        #expect(try await EventStreamTestUtil.events(nil as AsyncThrowingStream<Int, any Error>?) == [])
    }

    private func signedMessage(_ payload: Data) -> Message {
        Message(
            headers: [
                Header(name: ":date", value: .timestamp(Date(timeIntervalSince1970: 0))),
                Header(name: ":chunk-signature", value: .byteArray(Data(repeating: 0xAB, count: 32))),
            ],
            payload: payload
        )
    }
}
