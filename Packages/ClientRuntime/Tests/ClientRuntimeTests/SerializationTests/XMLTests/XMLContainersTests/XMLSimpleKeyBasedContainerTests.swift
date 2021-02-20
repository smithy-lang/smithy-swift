/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class XMLSimpleKeyBasedContainerTests: XCTestCase {

    func testIsNull() {
        let box = XMLSimpleKeyBasedContainer(key: "key", element: XMLStringContainer(xmlString: "value"))
        XCTAssertEqual(box.isNull, false)
    }

    func testXMLString() {
        let box = XMLSimpleKeyBasedContainer(key: "key", element: XMLStringContainer(xmlString: "value"))
        XCTAssertNil(box.xmlString)
    }
}
