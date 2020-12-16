/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class XMLFloatFamilyContainers: XCTestCase {

    func testIsNull() {
        let box = XMLDecimalContainer(42.0)
        XCTAssertEqual(box.isNull, false)
    }

    func testUnbox() {
        let values: [Decimal] = [
            -1.23,
            12_678_967.543233,
            +100_000.00,
            210
        ]

        for unboxed in values {
            let box = XMLDecimalContainer(unboxed)
            XCTAssertEqual(box.unboxed, unboxed)
        }
    }

    func testXMLString() {
        let values: [(Decimal, String)] = [
            (12.34, "12.34"),
            (0.0, "0")
        ]

        for (bool, string) in values {
            let box = XMLDecimalContainer(bool)
            XCTAssertEqual(box.xmlString, string)
        }
    }

    func testValidValues() {
        let values: [String] = [
            "-1.23",
            "12678967.543233",
            "+100000.00",
            "210"
        ]

        for string in values {
            let box = XMLDecimalContainer(xmlString: string)
            XCTAssertNotNil(box)
        }
    }

    func testInvalidValues() {
        let values: [String] = [
            "foobar",
            ""
        ]

        for string in values {
            let box = XMLDecimalContainer(xmlString: string)
            XCTAssertNil(box)
        }
    }

    func testFloatIsNull() {
        let box = XMLFloatContainer(42.0)
        XCTAssertEqual(box.isNull, false)
    }

    func testFloatUnbox() {
        let values: [XMLFloatContainer.Unboxed] = [
            -3e2,
            4268.22752e11,
            +24.3e-3,
            12,
            +3.5,
            -.infinity,
            -0
        ]

        for unboxed in values {
            let box = XMLFloatContainer(unboxed)
            XCTAssertEqual(box.unboxed, unboxed)
        }
    }

    func testFloatXMLString() {
        let values: [(XMLFloatContainer.Unboxed, String)] = [
            (42.0, "42.0"),
            (.infinity, "INF"),
            (-.infinity, "-INF"),
            (.nan, "NaN")
        ]

        for (double, string) in values {
            let box = XMLFloatContainer(double)
            XCTAssertEqual(box.xmlString, string)
        }
    }

    func testFloatValidValues() {
        let values: [String] = [
            "-3E2",
            "4268.22752E11",
            "+24.3e-3",
            "12",
            "+3.5",
            "-INF",
            "-0",
            "NaN"
        ]

        for string in values {
            let box = XMLFloatContainer(xmlString: string)
            XCTAssertNotNil(box)
        }
    }

    func testFloatInvalidValues() {
        let values: [String] = [
            "-3E2.4",
            "12E",
            "foobar",
            ""
        ]

        for string in values {
            let box = XMLFloatContainer(xmlString: string)
            XCTAssertNil(box)
        }
    }
}
