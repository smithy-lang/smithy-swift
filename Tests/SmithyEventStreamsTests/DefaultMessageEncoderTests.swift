//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyEventStreams
import XCTest

final class DefaultMessageEncoderTests: XCTestCase {

    let sut = DefaultMessageEncoder()

    func testEncode_MessageWithAllHeaders() {
        let encodedMessage = try! sut.encode(message: EventStreamTestData.validMessageWithAllHeaders())
        XCTAssertEqual(EventStreamTestData.validMessageDataWithAllHeaders(), encodedMessage)
    }

    func testEncode_MessageWithEmptyPayload() {
        let encodedMessage = try! sut.encode(message: EventStreamTestData.validMessageEmptyPayload())
        XCTAssertEqual(EventStreamTestData.validMessageDataEmptyPayload(), encodedMessage)
    }

    func testEncode_MessageWithNoHeaders() {
        let encodedMessage = try! sut.encode(message: EventStreamTestData.validMessageNoHeaders())
        XCTAssertEqual(EventStreamTestData.validMessageDataNoHeaders(), encodedMessage)
    }
}
