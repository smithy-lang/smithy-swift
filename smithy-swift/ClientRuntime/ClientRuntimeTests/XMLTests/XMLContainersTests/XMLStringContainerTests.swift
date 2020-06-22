// TODO:: Add copyrights

import XCTest
@testable import ClientRuntime

class XMLStringContainerTests: XCTestCase {

    func testIsNull() {
        let box = XMLStringContainer("lorem ipsum")
        XCTAssertEqual(box.isNull, false)
    }

    func testUnbox() {
        let values: [String] = [
            "",
            "false",
            "42",
            "12.34",
            "lorem ipsum",
        ]

        for unboxed in values {
            let box = XMLStringContainer(unboxed)
            XCTAssertEqual(box.unboxed, unboxed)
        }
    }

    func testXMLString() {
        let values: [(String, String)] = [
            ("", ""),
            ("false", "false"),
            ("42", "42"),
            ("12.34", "12.34"),
            ("lorem ipsum", "lorem ipsum"),
        ]

        for (unboxed, string) in values {
            let box = XMLStringContainer(unboxed)
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
            let box = XMLStringContainer(xmlString: string)
            XCTAssertNotNil(box)
        }
    }

    func testInvalidValues() {
        let values: [String] = [
            // none.
        ]

        for string in values {
            let box = XMLStringContainer(xmlString: string)
            XCTAssertNil(box)
        }
    }
}
