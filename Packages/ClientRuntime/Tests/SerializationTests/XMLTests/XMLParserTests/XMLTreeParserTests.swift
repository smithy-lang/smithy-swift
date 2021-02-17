/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class XMLTreeParserTests: XCTestCase {

    var parser: XMLTreeParser!

    override func setUp() {
        parser = XMLTreeParser()
    }

    func testValidXMLTreeParse() throws {

        let xmlString =
            """
            <container>
                <intValue>42</intValue>
                <stringValue>foo</stringValue>
            </container>
            """
        let xmlData = xmlString.data(using: .utf8)!

        let root: XMLElementRepresentable? = try parser.parse(
            with: xmlData,
            errorContextLength: 0,
            shouldProcessNamespaces: false
        )

        let expected = XMLElementRepresentable(
            key: "container",
            elements: [
                XMLElementRepresentable(
                    key: "intValue",
                    stringValue: "42"
                ),
                XMLElementRepresentable(
                    key: "stringValue",
                    stringValue: "foo"
                )
            ]
        )
        XCTAssertEqual(root, expected)
    }

    func testInValidXMLTreeParseFails() throws {

        let xmlString = "abraca dabra"
        let xmlData = xmlString.data(using: .utf8)!

        XCTAssertThrowsError(try parser.parse(
            with: xmlData,
            errorContextLength: 1,
            shouldProcessNamespaces: false
        ))
    }
}
