//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

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
