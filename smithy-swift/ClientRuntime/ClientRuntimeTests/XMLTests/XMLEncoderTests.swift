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

class XMLEncoderTests: XCTestCase {

    func testEncodingHomogenousDictionary() {
        let dictionary = ["LocationConstraint": "us-east-1",
                          "MaxRetries": "10.1",
                          "IsOwnner": "true"]
        
        let encoderOptions = XMLEncoderOptions(rootKey: "root", rootAttributes: ["xmlns": "http://s3.amazonaws.com/doc/2006-03-01/"])
        let encoder = XMLEncoder(options: encoderOptions)
        
        let xmlData = try? encoder.encode(dictionary)
        
        XCTAssertNotNil(xmlData)
        
        let xmlString = String(data: xmlData!, encoding: .utf8)
        
        XCTAssertEqual(xmlString!, """
                            <root xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><IsOwnner>true</IsOwnner><LocationConstraint>us-east-1</LocationConstraint><MaxRetries>10.1</MaxRetries></root>
                            """)
    }
}
