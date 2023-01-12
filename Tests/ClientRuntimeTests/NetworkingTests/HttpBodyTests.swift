//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AwsCommonRuntimeKit
@testable import ClientRuntime

class HttpBodyTests: XCTestCase {
    func testWhenDataIsEmptyThenIsEmptyIsTrue() {
        let data = Data()
        let body = HttpBody.data(data)
        XCTAssertTrue(body.isEmpty)
    }

    func testWhenDataIsNilThenIsEmptyIsTrue() {
        let body = HttpBody.data(nil)
        XCTAssertTrue(body.isEmpty)
    }

    func testWhenDataIsNotEmptyThenIsEmptyIsFalse() {
        let data = "foo".data(using: .utf8)!
        let body = HttpBody.data(data)
        XCTAssertFalse(body.isEmpty)
    }

    func testWhenStreamIsEmptyThenIsEmptyIsTrue() {
        let stream = ByteStream.from(data: Data())
        let body = HttpBody.stream(stream)
        XCTAssertTrue(body.isEmpty)
    }

    func testWhenStreamIsNotEmptyThenIsEmptyIsFalse() {
        let stream = ByteStream.from(data: "foo".data(using: .utf8)!)
        let body = HttpBody.stream(stream)
        XCTAssertFalse(body.isEmpty)
    }

    func testWhenBodyIsNoneThenIsEmptyIsTrue() {
        let body = HttpBody.none
        XCTAssertTrue(body.isEmpty)
    }
}
