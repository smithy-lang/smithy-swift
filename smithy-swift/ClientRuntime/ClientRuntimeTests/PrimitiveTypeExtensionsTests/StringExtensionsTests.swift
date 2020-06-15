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
    
    override func setUp() {
        
        camelCaseString = "myString"
        pascalCaseString = "MyString"
        stringWithDots = "my.string"
        kebabCaseString = "my-string"
    }

    func testCapitalizingFirstLetter() {
        camelCaseString.capitalizeFirstLetter()
        XCTAssertTrue(camelCaseString == pascalCaseString)
    }
    
    func testLowerCasingFirstLetter() {
        pascalCaseString.lowercaseFirstLetter()
        XCTAssertTrue(camelCaseString == pascalCaseString)
    }
    
    func testEscapingChars() {
        let escapedString = stringWithDots.escape([(".", "-")])
        XCTAssertTrue(escapedString == kebabCaseString)
    }
}
