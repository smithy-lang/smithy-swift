/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class BoolTests: XMLSimpleTypesTestsUtils {

    let values: [(Bool, String)] = [
        (false, "false"),
        (true, "true")
    ]

    func testBoolAsAttribute() {
        prepareEncoderForTestTypeAsAttribute()

        for (value, xmlString) in values {
            let xmlString = getSimpleXMLContainerString(value: xmlString, representation: .attribute)
            let xmlData = xmlString.data(using: .utf8)!

            guard let decoded = try? decoder.decode(Container<Bool>.self, from: xmlData) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Bool.self, context: .decoding, representation: .attribute))
                return
            }
            XCTAssertEqual(decoded.value, value)

            guard let encoded = try? encoder.encode(decoded) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Bool.self, context: .encoding, representation: .attribute))
                return
            }
            XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
        }
    }

    func testBoolAsElement() {
        for (value, xmlString) in values {
            let xmlString = getSimpleXMLContainerString(value: xmlString, representation: .element)
            let xmlData = xmlString.data(using: .utf8)!

            guard let decoded = try? decoder.decode(Container<Bool>.self, from: xmlData) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Bool.self, context: .decoding, representation: .element))
                return
            }
            XCTAssertEqual(decoded.value, value)

            guard let encoded = try? encoder.encode(decoded) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Bool.self, context: .encoding, representation: .element))
                return
            }
            XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
        }
    }
}
