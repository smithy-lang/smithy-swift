/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class XMLKeyTests: XCTestCase {

    func testInitWithStringValue() {
        let key = XMLKey(stringValue: "foo")

        XCTAssertNotNil(key)
        XCTAssertEqual(key!.stringValue, "foo")
        XCTAssertEqual(key!.intValue, nil)
    }

    func testInitWithIntValue() {
        let key = XMLKey(intValue: 42)

        XCTAssertNotNil(key)
        XCTAssertEqual(key!.stringValue, "42")
        XCTAssertEqual(key!.intValue, 42)
    }

    func testInitWithStringValueIntValue() {
        let key = XMLKey(stringValue: "foo", intValue: 42)

        XCTAssertEqual(key.stringValue, "foo")
        XCTAssertEqual(key.intValue, 42)
    }
}
