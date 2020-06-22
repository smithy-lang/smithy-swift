// TODO:: Add copyrights

import XCTest
@testable import ClientRuntime

class XMLBoolContainerTests: XCTestCase {
    
    func testIsNull() {
        let box = XMLBoolContainer(false)
        XCTAssertEqual(box.isNull, false)
    }

    func testUnbox() {
        let values: [Bool] = [
            false,
            true,
        ]

        for unboxed in values {
            let box = XMLBoolContainer(unboxed)
            XCTAssertEqual(box.unboxed, unboxed)
        }
    }

    func testXMLString() {
        let values: [(Bool, String)] = [
            (false, "false"),
            (true, "true"),
        ]

        for (unboxed, string) in values {
            let box = XMLBoolContainer(unboxed)
            XCTAssertEqual(box.xmlString, string)
        }
    }

    func testValidValues() {
        let values: [String] = [
            "0",
            "1",
            "false",
            "true",
        ]

        for string in values {
            let box = XMLBoolContainer(xmlString: string)
            XCTAssertNotNil(box)
        }
    }

    func testInvalidValues() {
        let values: [String] = [
            "42",
            "foobar",
            "",
        ]

        for string in values {
            let box = XMLBoolContainer(xmlString: string)
            XCTAssertNil(box)
        }
    }
}
