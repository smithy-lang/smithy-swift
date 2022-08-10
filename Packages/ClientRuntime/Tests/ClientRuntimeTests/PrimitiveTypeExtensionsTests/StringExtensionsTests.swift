/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class StringExtensionsTests: XCTestCase {

    var camelCaseString: String!
    var pascalCaseString: String!
    var stringWithDots: String!
    var kebabCaseString: String!
    var emptyString: String!

    override func setUp() {

        camelCaseString = "myString"
        pascalCaseString = "MyString"
        stringWithDots = "my.string"
        kebabCaseString = "my-string"
        emptyString = ""
    }

    func testCapitalizingFirstLetter() {
        camelCaseString.capitalizeFirstLetter()
        XCTAssertTrue(camelCaseString == pascalCaseString)

        emptyString.capitalizeFirstLetter()
        XCTAssertTrue(emptyString == "")
    }

    func testLowerCasingFirstLetter() {
        pascalCaseString.lowercaseFirstLetter()
        XCTAssertTrue(camelCaseString == pascalCaseString)

        emptyString.lowercaseFirstLetter()
        XCTAssertTrue(emptyString == "")
    }

    func testEscapingChars() {
        let escapedString = stringWithDots.escape([(".", "-")])
        XCTAssertTrue(escapedString == kebabCaseString)
    }
    
    func testValidBase64EncodedString() {
        let normalString = "ABC"
        guard let base64EncodedString = try? normalString.base64EncodedString() else {
            XCTFail("Failed to base64 encode a valid string")
            return
        }
        XCTAssertEqual(base64EncodedString, "QUJD")
    }
    
    func testTrimmingString() {
        let stringToTrim = "\t \n  ABC \n \t  "
        XCTAssertEqual(stringToTrim.trim(), "ABC")
    }
    
    func testRemovingPrefixFromString() {
        let stringWithPrefix = "X-Foo-ABC"
        XCTAssertEqual(stringWithPrefix.removePrefix("X-Foo-"), "ABC")
        
        let stringWithoutPrefix = "ABC"
        XCTAssertEqual(stringWithoutPrefix.removePrefix("X-Foo-"), "ABC")
    }
    
    func testDecodingBase64EncodedString() {
        let base64EncodedString = "dHJ1ZQ=="
        guard let decodedString = try? base64EncodedString.base64DecodedString() else {
            XCTFail("Failed to decode a valid base64 encoded string")
            return
        }
        XCTAssertEqual(decodedString, "true")
    }
    
    func testSubstringAfter() {
        let stringsAndMatches = [
            "FooError": "FooError",
            "ABC#FooError": "FooError",
            "#": ""
        ]
        for (string, match) in stringsAndMatches {
            XCTAssertEqual(string.substringAfter("#"), match)
        }
    }
    
    func testSubstringBefore() {
        let stringsAndMatches = [
            "FooError": "FooError",
            "FooError:ABC": "FooError",
            ":": ""
        ]
        for (string, match) in stringsAndMatches {
            XCTAssertEqual(string.substringBefore(":"), match)
        }
    }

    func testOffset() {
        let string = "FooBar"
        let offset = string[3]
        XCTAssertEqual("B", offset)
    }

    func testRange() {
        let string = "FooBar"
        let range = string[1...3]
        XCTAssertEqual("ooB", range)
    }

    func testClosedRange() {
        let string = "FooBar"
        let range = string[1...]
        XCTAssertEqual("ooBar", range)
    }

    func testPartialRangeThrough() {
        let string = "FooBar"
        let range = string[...3]
        XCTAssertEqual("FooB", range)
    }

    func testPartialRangeUpTo() {
        let string = "FooBar"
        let range = string[..<3]
        XCTAssertEqual("Foo", range)
    }

    func testPartialRangeFrom() {
        let string = "FooBar"
        let range = string[3...]
        XCTAssertEqual("Bar", range)
    }
}
