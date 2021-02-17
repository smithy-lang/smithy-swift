/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class ArrayTests: XMLSimpleTypesTestsUtils {

    struct ContainerWithArray<T: Codable & Equatable>: Codable, Equatable {
        let value: [T]
    }

    struct ContainerWithOptionalArray<T: Codable & Equatable>: Codable, Equatable {
        let value: [T]?
    }

    /* A non-optional array of any type is initialized to the default [] if the value is absent.
       This behavior is similar to Dictionary.
     */
    func testArrayOfStringAbsent() {
        let xmlString = "<container />"
        let xmlData = xmlString.data(using: .utf8)!

        guard let decoded = try? decoder.decode(ContainerWithArray<String>.self, from: xmlData) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [String].self, context: .decoding, representation: .element))
            return
        }
        XCTAssertEqual(decoded.value, [])

        guard let encoded = try? encoder.encode(decoded) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [String].self, context: .encoding, representation: .element))
            return
        }
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
    }

    func testArrayOfIntAbsent() {
        let xmlString = "<container />"
        let xmlData = xmlString.data(using: .utf8)!

        guard let decoded = try? decoder.decode(ContainerWithArray<Int>.self, from: xmlData) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [Int].self, context: .decoding, representation: .element))
            return
        }
        XCTAssertEqual(decoded.value, [])

        guard let encoded = try? encoder.encode(decoded) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [Int].self, context: .encoding, representation: .element))
            return
        }
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
    }

    /* An optional array of any type is initialized to nil if it is absent.
     */
    func testOptionalArrayOfStringAbsent() {
        let xmlString = "<container />"
        let xmlData = xmlString.data(using: .utf8)!

        guard let decoded = try? decoder.decode(ContainerWithOptionalArray<String>.self, from: xmlData) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [String].self, context: .decoding, representation: .element))
            return
        }
        XCTAssertNil(decoded.value)

        guard let encoded = try? encoder.encode(decoded) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [String].self, context: .encoding, representation: .element))
            return
        }
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
    }

    func testOptionalArrayOfIntAbsent() {
        let xmlString = "<container />"
        let xmlData = xmlString.data(using: .utf8)!

        guard let decoded = try? decoder.decode(ContainerWithOptionalArray<Int>.self, from: xmlData) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [Int].self, context: .decoding, representation: .element))
            return
        }
        XCTAssertNil(decoded.value)

        guard let encoded = try? encoder.encode(decoded) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [Int].self, context: .encoding, representation: .element))
            return
        }
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
    }

    /* The behavior when the array is present but has member values missing depends on the type of the member and the defaults it has if any.
       String has default of "" while Int has no such defaults.
     */
    func testArrayOfStringPresentWithNoValue() {
        let xmlString =
            """
            <container>
                <value></value>
            </container>
            """
        let xmlData = xmlString.data(using: .utf8)!

        guard let decoded = try? decoder.decode(ContainerWithArray<String>.self, from: xmlData) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [String].self, context: .decoding, representation: .element))
            return
        }
        XCTAssertEqual(decoded.value, [""])

        guard let encoded = try? encoder.encode(decoded) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [String].self, context: .encoding, representation: .element))
            return
        }
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
    }

    func testArrayOfIntPresentWithNoValue() {
        let xmlString =
            """
            <container>
                <value></value>
            </container>
            """
        let xmlData = xmlString.data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(ContainerWithArray<Int>.self, from: xmlData))
    }

    func testArrayOfOptionalStringPresentWithNoValue() {
        let xmlString =
            """
            <container>
                <value></value>
            </container>
            """
        let xmlData = xmlString.data(using: .utf8)!

        guard let decoded = try? decoder.decode(ContainerWithArray<String?>.self, from: xmlData) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [String?].self, context: .decoding, representation: .element))
            return
        }
        XCTAssertEqual(decoded.value, [""])

        guard let encoded = try? encoder.encode(decoded) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [String?].self, context: .encoding, representation: .element))
            return
        }
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
    }

    /* Array of optional ints will add nil as the entry to array if no value is provided for the entry
     */
    func testArrayOfOptionalIntPresentWithNoValue() {
        let xmlString =
            """
            <container>
                <value />
            </container>
            """
        let xmlData = xmlString.data(using: .utf8)!

        guard let decoded = try? decoder.decode(ContainerWithArray<Int?>.self, from: xmlData) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [Int?].self, context: .decoding, representation: .element))
            return
        }
        XCTAssertEqual(decoded.value, [nil])

        guard let encoded = try? encoder.encode(decoded) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [Int?].self, context: .encoding, representation: .element))
            return
        }
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
    }
}
