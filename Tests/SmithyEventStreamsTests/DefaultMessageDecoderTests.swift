//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum SmithyEventStreamsAPI.EventStreamError
import class SmithyEventStreams.DefaultMessageDecoder
import XCTest

final class DefaultMessageDecoderTests: XCTestCase {

    let sut = DefaultMessageDecoder()

    func testDecode_MessageWithAllHeaders() {
        try! sut.feed(data: EventStreamTestData.validMessageDataWithAllHeaders())
        let decodedMessage = try! sut.message()
        XCTAssertEqual(EventStreamTestData.validMessageWithAllHeaders(), decodedMessage)
    }

    func testDecode_MessageWithEmptyPayload() {
        try! sut.feed(data: EventStreamTestData.validMessageDataEmptyPayload())
        let decodedMessage = try! sut.message()
        XCTAssertEqual(EventStreamTestData.validMessageEmptyPayload(), decodedMessage)
    }

    func testDecode_MessageWithNoHeaders() {
        try! sut.feed(data: EventStreamTestData.validMessageDataNoHeaders())
        let decodedMessage = try! sut.message()
        XCTAssertEqual(EventStreamTestData.validMessageNoHeaders(), decodedMessage)
    }

    func testDecode_MessageWithInitialResponse() {
        try! sut.feed(data: EventStreamTestData.validInitialResponseMessageData())
        let decodedMessage = try! sut.message()
        // initialResponse message should not be added to the messageBuffer
        XCTAssertNil(decodedMessage)
    }

    func testEndOfStream_StreamClosed() {
        try! sut.feed(data: EventStreamTestData.validMessageDataNoHeaders()[0..<EventStreamTestData.validMessageDataNoHeaders().count-1])
        XCTAssertThrowsError(try sut.endOfStream()) { error in
            guard case EventStreamError.decoding(let message) = error else {
                return XCTFail()
            }

            XCTAssertEqual("Stream ended before message was complete", message)
        }
    }

    func testAwaitInitialResponse_MessageWithInitialResponse() async {
        try! sut.feed(data: EventStreamTestData.validInitialResponseMessageData())
        guard let initialResponse = await sut.awaitInitialResponse() else {
            XCTFail("Error!")
            return
        }

        var someMetadata: String? = nil

        // test expected codegen
        let decoder = JSONDecoder()
        do {
            let response = try decoder.decode([String: String].self, from: initialResponse)
            someMetadata = response["someMetadata"]
        } catch {
            print("Error decoding JSON: \(error)")
            someMetadata = nil
        }

        XCTAssertEqual(
            String(data: EventStreamTestData.validInitialResponseMessage().payload, encoding: .utf8),
            String(data: initialResponse, encoding: .utf8)
        )

        if let someMetadataValue = someMetadata {
            XCTAssertEqual(someMetadataValue, "test")
        } else {
            XCTFail("someMetadataValue is nil")
        }
    }
}
