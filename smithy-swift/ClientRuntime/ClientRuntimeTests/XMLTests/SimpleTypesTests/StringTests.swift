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


class StringTests: SimpleTypesTestsUtils {

    let values: [(String, String)] = [
        ("false", "false"),
        ("-42", "-42"),
        ("42", "42"),
        ("42.0", "42.0"),
        ("foobar", "foobar")
    ]

    func testStringAsAttribute() {
        prepareEncoderForTestTypeAsAttribute()
        
        for (value, xmlString) in values {
            let xmlString = getSimpleXMLContainerString(value: xmlString, representation: .attribute)
            let xmlData = xmlString.data(using: .utf8)!

            guard let decoded = try? decoder.decode(Container<String>.self, from: xmlData) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: String.self, context: .decoding, representation: .attribute))
                return
            }
            XCTAssertEqual(decoded.value, value)

            guard let encoded = try? encoder.encode(decoded) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: String.self, context: .encoding, representation: .attribute))
                return
            }
            XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
        }
    }

    func testStringAsElement() {
        for (value, xmlString) in values {
            let xmlString = getSimpleXMLContainerString(value: xmlString, representation: .element)
            let xmlData = xmlString.data(using: .utf8)!

            guard let decoded = try? decoder.decode(Container<String>.self, from: xmlData) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: String.self, context: .decoding, representation: .element))
                return
            }
            XCTAssertEqual(decoded.value, value)

            guard let encoded = try? encoder.encode(decoded) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: String.self, context: .encoding, representation: .element))
                return
            }
            XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
        }
    }

}
