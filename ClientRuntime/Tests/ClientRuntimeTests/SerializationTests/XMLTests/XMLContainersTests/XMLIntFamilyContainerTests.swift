/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class XMLIntFamilyContainerTests: XCTestCase {

    func testIsNull() {
        let box = XMLIntContainer(-42)
        XCTAssertEqual(box.isNull, false)
    }

    func testUnbox() {
        let values: [Int] = [
            -42,
            42,
            0
        ]

        for unboxed in values {
            let box = XMLIntContainer(unboxed)
            XCTAssertEqual(box.unbox(), unboxed)
        }
    }

    func testXMLString() {
        let values: [(Int, String)] = [
            (-42, "-42"),
            (42, "42"),
            (0, "0")
        ]

        for (unboxed, string) in values {
            let box = XMLIntContainer(unboxed)
            XCTAssertEqual(box.xmlString, string)
        }
    }

    func testValidValues() {
        let values: [String] = [
            "-1",
            "0",
            "12678967543233",
            "+100000"
        ]

        for string in values {
            let box = XMLIntContainer(xmlString: string)
            XCTAssertNotNil(box)
        }
    }

    func testInvalidValues() {
        let values: [String] = [
            "foobar",
            ""
        ]

        for string in values {
            let box = XMLIntContainer(xmlString: string)
            XCTAssertNil(box)
        }
    }

    func testUIntIsNull() {
        let box = XMLUIntContainer(UInt(42))
        XCTAssertEqual(box.isNull, false)
    }

    func testUIntUnbox() {
        let values: [UInt] = [
            1,
            0,
            12_678_967_543_233
        ]

        for unboxed in values {
            let box = XMLUIntContainer(unboxed)
            XCTAssertEqual(box.unbox(), unboxed)
        }
    }

    func testUIntXMLString() {
        let values: [(UInt, String)] = [
            (1, "1"),
            (0, "0"),
            (12_678_967_543_233, "12678967543233")
        ]

        for (unboxed, string) in values {
            let box = XMLUIntContainer(unboxed)
            XCTAssertEqual(box.xmlString, string)
        }
    }

    func testUIntValidValues() {
        let values: [String] = [
            "1",
            "0",
            "12678967543233",
            "+100000"
        ]

        for string in values {
            let box = XMLUIntContainer(xmlString: string)
            XCTAssertNotNil(box)
        }
    }

    func testUIntInvalidValues() {
        let values: [String] = [
            "-1",
            "foobar",
            ""
        ]

        for string in values {
            let box = XMLUIntContainer(xmlString: string)
            XCTAssertNil(box)
        }
    }
}
