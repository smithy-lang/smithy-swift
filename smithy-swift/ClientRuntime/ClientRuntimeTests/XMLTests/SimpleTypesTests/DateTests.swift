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

class DateTests: XMLSimpleTypesTestsUtils {

    let values: [(Date, String)] = [
        (Date(timeIntervalSince1970: 0.0), "0.0"),
    ]

    func testDateAsAttribute() {
        prepareEncoderForTestTypeAsAttribute()
        encoder.dateEncodingStrategy = .secondsSince1970
        decoder.dateDecodingStrategy = .secondsSince1970
        
        for (value, xmlString) in values {
            let xmlString = getSimpleXMLContainerString(value: xmlString, representation: .attribute)
            let xmlData = xmlString.data(using: .utf8)!

            guard let decoded = try? decoder.decode(Container<Date>.self, from: xmlData) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Date.self, context: .decoding, representation: .attribute))
                return
            }
            XCTAssertEqual(decoded.value, value)

            guard let encoded = try? encoder.encode(decoded) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Date.self, context: .encoding, representation: .attribute))
                return
            }
            XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
        }
    }

    func testDateAsElement() {
        encoder.dateEncodingStrategy = .secondsSince1970
        decoder.dateDecodingStrategy = .secondsSince1970
        
        for (value, xmlString) in values {
            let xmlString = getSimpleXMLContainerString(value: xmlString, representation: .element)
            let xmlData = xmlString.data(using: .utf8)!

            guard let decoded = try? decoder.decode(Container<Date>.self, from: xmlData) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Date.self, context: .decoding, representation: .element))
                return
            }
            XCTAssertEqual(decoded.value, value)

            guard let encoded = try? encoder.encode(decoded) else {
                XCTFail(getCodingSimpleTypeFailureMessage(type: Date.self, context: .encoding, representation: .element))
                return
            }
            XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
        }
    }
    
    func testCustomDateFormatter() {
        let dateString = "20:32 Wed, 30 Oct 2019Z"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm E, d MMM y'Z"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        guard let formattedDate = dateFormatter.date(from: dateString) else {
            XCTFail("could not format date")
            return
        }
        
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        let xmlString =
            """
            <container>
                <value>\(dateString)</value>
            </container>
            """
        let xmlData = xmlString.data(using: .utf8)!

        guard let decoded = try? decoder.decode(Container<Date>.self, from: xmlData) else {
            XCTFail("Decoding with custom date formatter failed")
            return
        }
        XCTAssertEqual(decoded.value, formattedDate)

        guard let encoded = try? encoder.encode(decoded) else {
            XCTFail("Encoding with custom date formatter failed")
            return
        }
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, xmlString)
    }

}
