/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class IntFamilyTests: XMLSimpleTypesTestsUtils {

    let intValues: [(Int, String)] = [
        (-4, "-4"),
        (0, "0"),
        (4, "4")
    ]

    let uIntValues: [(UInt, String)] = [
        (0, "0"),
        (4, "4")
    ]

    func testIntAsAttribute() {
        prepareEncoderForTestTypeAsAttribute()

        for (value, xmlString) in intValues {
            let xmlString = getSimpleXMLContainerString(value: xmlString, representation: .attribute)
            let xmlData = xmlString.data(using: .utf8)!

            guard let decoded = try? decoder.decode(Container<Int>.self, from: xmlData) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Int.self, context: .decoding, representation: .attribute))
                return
            }
            XCTAssertEqual(decoded.value, value)

            guard let encoded = try? encoder.encode(decoded) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Int.self, context: .encoding, representation: .attribute))
                return
            }
            XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
        }
    }

    func testIntAsElement() {
        for (value, xmlString) in intValues {
            let xmlString = getSimpleXMLContainerString(value: xmlString, representation: .element)
            let xmlData = xmlString.data(using: .utf8)!

            guard let decoded = try? decoder.decode(Container<Int>.self, from: xmlData) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Int.self, context: .decoding, representation: .element))
                return
            }
            XCTAssertEqual(decoded.value, value)

            guard let encoded = try? encoder.encode(decoded) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Int.self, context: .encoding, representation: .element))
                return
            }
            XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
        }
    }

    func testUIntAsAttribute() {
        prepareEncoderForTestTypeAsAttribute()

        for (value, xmlString) in uIntValues {
            let xmlString = getSimpleXMLContainerString(value: xmlString, representation: .attribute)
            let xmlData = xmlString.data(using: .utf8)!

            guard let decoded = try? decoder.decode(Container<UInt>.self, from: xmlData) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: UInt.self, context: .decoding, representation: .attribute))
                return
            }
            XCTAssertEqual(decoded.value, value)

            guard let encoded = try? encoder.encode(decoded) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: UInt.self, context: .encoding, representation: .attribute))
                return
            }
            XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
        }
    }

    func testUIntAsElement() {
        for (value, xmlString) in uIntValues {
            let xmlString = getSimpleXMLContainerString(value: xmlString, representation: .element)
            let xmlData = xmlString.data(using: .utf8)!

            guard let decoded = try? decoder.decode(Container<UInt>.self, from: xmlData) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: UInt.self, context: .decoding, representation: .element))
                return
            }
            XCTAssertEqual(decoded.value, value)

            guard let encoded = try? encoder.encode(decoded) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: UInt.self, context: .encoding, representation: .element))
                return
            }
            XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
        }
    }

}
