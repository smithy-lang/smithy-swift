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

class DictionaryTests: XMLSimpleTypesTestsUtils {
    
    func testCodingDictionary() {
        let value = ["bar": 1, "foo": 2]
        let xmlString =
            """
            <container>
                <value>
                    <bar>1</bar>
                    <foo>2</foo>
                </value>
            </container>
            """
        
        let xmlData = xmlString.data(using: .utf8)!
        
        guard let decoded = try? decoder.decode(Container<[String:Int]>.self, from: xmlData) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [String:Int].self, context: .decoding, representation: .element))
            return
        }
        XCTAssertEqual(decoded.value, value)
        
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        guard let encoded = try? encoder.encode(decoded) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [String:Int].self, context: .encoding, representation: .element))
            return
        }
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
    }
    
    func testMissingDictionary() {
        let xmlString = "<container />"
        let value: [String:Int] = [:]
        let xmlData = xmlString.data(using: .utf8)!

        guard let decoded = try? decoder.decode(Container<[String:Int]>.self, from: xmlData) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [String:Int].self, context: .decoding, representation: .element))
            return
        }
        XCTAssertEqual(decoded.value, value)

        guard let encoded = try? encoder.encode(decoded) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: [String:Int].self, context: .encoding, representation: .element))
            return
        }
        
        let expectedXMLString =
            """
            <container>
                <value />
            </container>
            """
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, expectedXMLString)
    }
    
    func testMissingDictionaryValue() {
        let xmlString =
        """
        <container>
            <value />
        </container>
        """
        let xmlData = xmlString.data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(Container<[String:Int]>.self, from: xmlData))
    }

}
