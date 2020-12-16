/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class XMLNullContainerTests: XCTestCase {

    let box = XMLNullContainer()

    func testIsNull() {
        XCTAssertEqual(box.isNull, true)
    }

    func testXMLString() {
        XCTAssertEqual(box.xmlString, nil)
    }

    func testEqual() {
        XCTAssertEqual(box, XMLNullContainer())
    }

    func testDescription() {
        XCTAssertEqual(box.description, "null")
    }
}
