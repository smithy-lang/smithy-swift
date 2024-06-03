//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import XCTest
import AwsCommonRuntimeKit
@testable import ClientRuntime

class HttpBodyTests: XCTestCase {
    func testWhenDataIsEmptyThenIsEmptyIsTrue() {
        let data = Data()
        let body = ByteStream.data(data)
        XCTAssertTrue(body.isEmpty)
    }

    func testWhenDataIsNilThenIsEmptyIsTrue() {
        let body = ByteStream.data(nil)
        XCTAssertTrue(body.isEmpty)
    }

    func testWhenDataIsNotEmptyThenIsEmptyIsFalse() {
        let data = "foo".data(using: .utf8)!
        let body = ByteStream.data(data)
        XCTAssertFalse(body.isEmpty)
    }

    func testWhenStreamIsEmptyThenIsEmptyIsTrue() {
        _ = BufferedStream(data: .init())
        let body = ByteStream.stream(BufferedStream())
        XCTAssertTrue(body.isEmpty)
    }

    func testWhenStreamIsNotEmptyThenIsEmptyIsFalse() {
        let stream = BufferedStream(data: .init("foo".data(using: .utf8)!))
        let body = ByteStream.stream(stream)
        XCTAssertFalse(body.isEmpty)
    }

    func testWhenBodyIsNoneThenIsEmptyIsTrue() {
        let body = ByteStream.noStream
        XCTAssertTrue(body.isEmpty)
    }
}
