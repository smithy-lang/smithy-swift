/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class XMLEncoderTests: XCTestCase {

    func testEncodingHomogenousDictionary() {
        let dictionary = ["LocationConstraint": "us-east-1",
                          "MaxRetries": "10.1",
                          "IsOwnner": "true"]

        let encoderOptions = XMLEncoderOptions(rootKey: "root",
                                               rootAttributes: ["xmlns": "http://s3.amazonaws.com/doc/2006-03-01/"])
        let encoder = XMLEncoder(options: encoderOptions)

        let xmlData = try? encoder.encode(dictionary)

        XCTAssertNotNil(xmlData)

        let xmlString = String(data: xmlData!, encoding: .utf8)
        // swiftlint:disable line_length
        let expectedXMLString =
            """
            <root xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><IsOwnner>true</IsOwnner><LocationConstraint>us-east-1</LocationConstraint><MaxRetries>10.1</MaxRetries></root>
            """

        XCTAssertEqual(xmlString!, expectedXMLString)
    }
}
