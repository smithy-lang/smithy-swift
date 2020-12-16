/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class XMLURLContainerTests: XCTestCase {

    func testIsNull() {
        let box = XMLURLContainer(URL(string: "http://example.com")!)
        XCTAssertEqual(box.isNull, false)
    }

    func testUnbox() {
        let values: [URL] = [
            URL(string: "file:///")!,
            URL(string: "http://example.com")!
        ]

        for unboxed in values {
            let box = XMLURLContainer(unboxed)
            XCTAssertEqual(box.unboxed, unboxed)
        }
    }

    func testXMLString() {
        let values: [(URL, String)] = [
            (URL(string: "file:///")!, "file:///"),
            (URL(string: "http://example.com")!, "http://example.com")
        ]

        for (bool, string) in values {
            let box = XMLURLContainer(bool)
            XCTAssertEqual(box.xmlString, string)
        }
    }

    func testValidValues() {
        let values: [String] = [
            "file:///",
            "http://example.com"
        ]

        for string in values {
            let box = XMLURLContainer(xmlString: string)
            XCTAssertNotNil(box)
        }
    }

    func testInvalidValues() {
        let values: [String] = [
            "foo\nbar",
            ""
        ]

        for string in values {
            let box = XMLURLContainer(xmlString: string)
            XCTAssertNil(box)
        }
    }
}
