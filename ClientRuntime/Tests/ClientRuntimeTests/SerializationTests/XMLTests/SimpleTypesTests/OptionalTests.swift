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

class OptionalTests: XMLSimpleTypesTestsUtils {

    private struct ContainerWithOptionalStringMember: Codable, Equatable {
        var optional: String?
    }

    private struct ContainerWithOptionalIntMember: Codable, Equatable {
        var optional: Int?
    }

    /* An optional member of any type is initialized to nil if it is absent.
      */
    func testOptionalStringMemberAbsent() {
        let xmlString =
            """
            <container />
            """
        let xmlData = xmlString.data(using: .utf8)!

        guard let decoded = try? decoder.decode(ContainerWithOptionalStringMember.self, from: xmlData) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: String?.self, context: .decoding, representation: .element))
            return
        }
        XCTAssertNil(decoded.optional)

        guard let encoded = try? encoder.encode(decoded) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: String?.self, context: .encoding, representation: .element))
            return
        }
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
    }

    func testOptionalIntMemberAbsent() {
        let xmlString =
            """
            <container />
            """
        let xmlData = xmlString.data(using: .utf8)!

        guard let decoded = try? decoder.decode(ContainerWithOptionalIntMember.self, from: xmlData) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: Int?.self, context: .decoding, representation: .element))
            return
        }
        XCTAssertNil(decoded.optional)

        guard let encoded = try? encoder.encode(decoded) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: Int?.self, context: .encoding, representation: .element))
            return
        }
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
    }

    /* String has a default value of "" while Int has no such defaults
     */
    func testOptionalStringMemberPresentWithNoValue() {
        let xmlString =
            """
            <container>
                <optional></optional>
            </container>
            """
        let xmlData = xmlString.data(using: .utf8)!

        guard let decoded = try? decoder.decode(ContainerWithOptionalStringMember.self, from: xmlData) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: String?.self, context: .decoding, representation: .element))
            return
        }
        XCTAssertEqual(decoded.optional, "")

        guard let encoded = try? encoder.encode(decoded) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: String?.self, context: .encoding, representation: .element))
            return
        }
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
    }

    func testOptionalIntMemberPresentWithNoValue() {
        let xmlString =
            """
            <container>
                <optional></optional>
            </container>
            """
        let xmlData = xmlString.data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(ContainerWithOptionalIntMember.self, from: xmlData))

        guard let encoded = try? encoder.encode(ContainerWithOptionalIntMember()) else {
            XCTFail(getCodingSimpleTypeFailureMessage(type: Int?.self, context: .encoding, representation: .element))
            return
        }

        let expectedXMLString = "<container />"
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, expectedXMLString)
    }

}
