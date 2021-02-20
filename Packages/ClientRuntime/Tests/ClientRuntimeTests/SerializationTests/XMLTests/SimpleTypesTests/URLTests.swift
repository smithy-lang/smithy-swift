/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class URLTests: XMLSimpleTypesTestsUtils {

    let values: [(URL, String)] = [
        (URL(string: "file:///")!, "file:///"),
        (URL(string: "http://example.com")!, "http://example.com")
    ]

    func testURLAsAttribute() {
        prepareEncoderForTestTypeAsAttribute()

        for (value, xmlString) in values {
            let xmlString = getSimpleXMLContainerString(value: xmlString, representation: .attribute)
            let xmlData = xmlString.data(using: .utf8)!

            guard let decoded = try? decoder.decode(Container<URL>.self, from: xmlData) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: URL.self, context: .decoding, representation: .attribute))
                return
            }
            XCTAssertEqual(decoded.value, value)

            guard let encoded = try? encoder.encode(decoded) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: URL.self, context: .encoding, representation: .attribute))
                return
            }
            XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
        }
    }

    func testURLAsElement() {
        for (value, xmlString) in values {
            let xmlString = getSimpleXMLContainerString(value: xmlString, representation: .element)
            let xmlData = xmlString.data(using: .utf8)!

            guard let decoded = try? decoder.decode(Container<URL>.self, from: xmlData) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: URL.self, context: .decoding, representation: .element))
                return
            }
            XCTAssertEqual(decoded.value, value)

            guard let encoded = try? encoder.encode(decoded) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: URL.self, context: .encoding, representation: .element))
                return
            }
            XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
        }
    }

}
