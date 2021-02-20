/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class DictionaryTests: XMLSimpleTypesTestsUtils {

    func testCodingDictionary() {
        let value = ["bar": 1, "foo": 2]
        let xmlString =
            """
            <container>
                <value>
                    <bar>1</bar>
                    <foo>2</foo>
                </value>
            </container>
            """

        let xmlData = xmlString.data(using: .utf8)!

        guard let decoded = try? decoder.decode(Container<[String: Int]>.self, from: xmlData) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [String: Int].self, context: .decoding, representation: .element))
            return
        }
        XCTAssertEqual(decoded.value, value)

        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        guard let encoded = try? encoder.encode(decoded) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [String: Int].self, context: .encoding, representation: .element))
            return
        }
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
    }

    func testMissingDictionary() {
        let xmlString = "<container />"
        let value: [String: Int] = [:]
        let xmlData = xmlString.data(using: .utf8)!

        guard let decoded = try? decoder.decode(Container<[String: Int]>.self, from: xmlData) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [String: Int].self, context: .decoding, representation: .element))
            return
        }
        XCTAssertEqual(decoded.value, value)

        guard let encoded = try? encoder.encode(decoded) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [String: Int].self, context: .encoding, representation: .element))
            return
        }

        let expectedXMLString =
            """
            <container>
                <value />
            </container>
            """
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, expectedXMLString)
    }

    func testMissingDictionaryValue() {
        let xmlString =
        """
        <container>
            <value />
        </container>
        """
        let xmlData = xmlString.data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(Container<[String: Int]>.self, from: xmlData))
    }

}
