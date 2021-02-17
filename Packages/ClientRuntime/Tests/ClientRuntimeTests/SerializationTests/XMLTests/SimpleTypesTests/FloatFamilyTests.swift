/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class FloatFamilyTests: XMLSimpleTypesTestsUtils {

    let decimalValues: [(Decimal, String)] = [
        (Decimal(-12.34), "-12.34"),
        (Decimal(0.0), "0"),
        (Decimal(12.34), "12.34")
    ]

    let floatValues: [(Float, String)] = [
        (-3.14, "-3.14"),
        (0.0, "0.0"),
        (3.14, "3.14")
    ]

    func testDecimalAsAttribute() {
        prepareEncoderForTestTypeAsAttribute()

        for (value, xmlString) in decimalValues {
            let xmlString = getSimpleXMLContainerString(value: xmlString, representation: .attribute)
            let xmlData = xmlString.data(using: .utf8)!

            guard let decoded = try? decoder.decode(Container<Decimal>.self, from: xmlData) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Decimal.self, context: .decoding, representation: .attribute))
                return
            }
            XCTAssertEqual(decoded.value, value)

            guard let encoded = try? encoder.encode(decoded) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Decimal.self, context: .encoding, representation: .attribute))
                return
            }
            XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
        }
    }

    func testDecimalAsElement() {
        for (value, xmlString) in decimalValues {
            let xmlString = getSimpleXMLContainerString(value: xmlString, representation: .element)
            let xmlData = xmlString.data(using: .utf8)!

            guard let decoded = try? decoder.decode(Container<Decimal>.self, from: xmlData) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Decimal.self, context: .decoding, representation: .element))
                return
            }
            XCTAssertEqual(decoded.value, value)

            guard let encoded = try? encoder.encode(decoded) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Decimal.self, context: .encoding, representation: .element))
                return
            }
            XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
        }
    }

    func testFloatAsAttribute() {
        prepareEncoderForTestTypeAsAttribute()

        for (value, xmlString) in floatValues {
            let xmlString = getSimpleXMLContainerString(value: xmlString, representation: .attribute)
            let xmlData = xmlString.data(using: .utf8)!

            guard let decoded = try? decoder.decode(Container<Float>.self, from: xmlData) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Float.self, context: .decoding, representation: .attribute))
                return
            }
            XCTAssertEqual(decoded.value, value)

            guard let encoded = try? encoder.encode(decoded) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Float.self, context: .encoding, representation: .attribute))
                return
            }
            XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
        }
    }

    func testFloatAsElement() {
        for (value, xmlString) in floatValues {
            let xmlString = getSimpleXMLContainerString(value: xmlString, representation: .element)
            let xmlData = xmlString.data(using: .utf8)!

            guard let decoded = try? decoder.decode(Container<Float>.self, from: xmlData) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Float.self, context: .decoding, representation: .element))
                return
            }
            XCTAssertEqual(decoded.value, value)

            guard let encoded = try? encoder.encode(decoded) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Float.self, context: .encoding, representation: .element))
                return
            }
            XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
        }
    }

}
