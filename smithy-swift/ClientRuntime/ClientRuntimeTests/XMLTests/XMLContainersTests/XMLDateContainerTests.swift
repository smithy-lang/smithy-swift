// TODO:: Add copyrights

import XCTest
@testable import ClientRuntime

class XMLDateContainerTests: XCTestCase {

    let customFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    func testIsNull() {
        let box = XMLDateContainer(Date(), format: .iso8601)
        XCTAssertEqual(box.isNull, false)
    }

    func testUnbox() {
        let values: [Date] = [
            Date(timeIntervalSince1970: 0.0),
            Date(timeIntervalSinceReferenceDate: 0.0),
            Date()
        ]

        for unboxed in values {
            let box = XMLDateContainer(unboxed, format: .iso8601)
            XCTAssertEqual(box.unboxed, unboxed)
        }
    }

    func testValidStrings_secondsSince1970() {
        let xmlStrings = [
            "-1000.0",
            "0.0",
            "1000.0"
        ]

        for xmlString in xmlStrings {
            let boxOrNil = XMLDateContainer(secondsSince1970: xmlString)
            XCTAssertNotNil(boxOrNil)

            guard let box = boxOrNil else { continue }

            XCTAssertEqual(box.xmlString, xmlString)
        }
    }

    func testValidStrings_millisecondsSince1970() {
        let xmlStrings = [
            "-1000.0",
            "0.0",
            "1000.0"
        ]

        for xmlString in xmlStrings {
            let boxOrNil = XMLDateContainer(millisecondsSince1970: xmlString)
            XCTAssertNotNil(boxOrNil)

            guard let box = boxOrNil else { continue }

            XCTAssertEqual(box.xmlString, xmlString)
        }
    }

    func testValidStrings_iso8601() {
        let xmlStrings = [
            "1970-01-23T01:23:45Z"
        ]

        for xmlString in xmlStrings {
            let boxOrNil = XMLDateContainer(iso8601: xmlString)
            XCTAssertNotNil(boxOrNil)

            guard let box = boxOrNil else { continue }

            XCTAssertEqual(box.xmlString, xmlString)
        }
    }

    func testValidStrings_formatter() {
        let xmlStrings = [
            "1970-01-23 01:23:45"
        ]

        for xmlString in xmlStrings {
            let boxOrNil = XMLDateContainer(xmlString: xmlString, formatter: customFormatter)
            XCTAssertNotNil(boxOrNil)

            guard let box = boxOrNil else { continue }

            XCTAssertEqual(box.xmlString, xmlString)
        }
    }

    func testInvalidStrings_secondsSince1970() {
        let xmlStrings = [
            "lorem ipsum",
            ""
        ]

        for xmlString in xmlStrings {
            let boxOrNil = XMLDateContainer(secondsSince1970: xmlString)
            XCTAssertNil(boxOrNil)
        }
    }

    func testInvalidStrings_millisecondsSince1970() {
        let xmlStrings = [
            "lorem ipsum",
            ""
        ]

        for xmlString in xmlStrings {
            let boxOrNil = XMLDateContainer(millisecondsSince1970: xmlString)
            XCTAssertNil(boxOrNil)
        }
    }

    func testInvalidStrings_iso8601() {
        let xmlStrings = [
            "lorem ipsum",
            ""
        ]

        for xmlString in xmlStrings {
            let boxOrNil = XMLDateContainer(iso8601: xmlString)
            XCTAssertNil(boxOrNil)
        }
    }

    func testInvalidStrings_formatter() {
        let xmlStrings = [
            "lorem ipsum",
            ""
        ]

        for xmlString in xmlStrings {
            let boxOrNil = XMLDateContainer(xmlString: xmlString, formatter: customFormatter)
            XCTAssertNil(boxOrNil)
        }
    }

}
