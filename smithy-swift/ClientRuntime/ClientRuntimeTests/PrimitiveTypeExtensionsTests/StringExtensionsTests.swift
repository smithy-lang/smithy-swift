//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

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
        XCTAssertEqual(stringWithPrefix.removingPrefix("X-Foo-"), "ABC")
        
        let stringWithoutPrefix = "ABC"
        XCTAssertEqual(stringWithoutPrefix.removingPrefix("X-Foo-"), "ABC")
    }
}
