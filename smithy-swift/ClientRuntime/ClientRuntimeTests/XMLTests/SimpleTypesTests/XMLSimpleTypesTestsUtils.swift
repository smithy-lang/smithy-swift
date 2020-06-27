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

class XMLSimpleTypesTestsUtils: XCTestCase {

    var decoder: XMLDecoder!
    var encoder: XMLEncoder!
    var encoderOptions: XMLEncoderOptions!
    var decoderOptions: XMLDecoderOptions!

    struct Container<T: Codable>: Codable {
        let value: T
    }

    override func setUp() {
        encoderOptions = XMLEncoderOptions(outputFormatting: XMLEncoder.OutputFormatting.prettyPrinted, rootKey: "container")
        encoder = XMLEncoder(options: encoderOptions)

        decoderOptions = XMLDecoderOptions()
        decoder = XMLDecoder(options: decoderOptions)
    }

    func testMissing() {
        let xmlString = "<container />"
        let xmlData = xmlString.data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(Container<Bool>.self, from: xmlData))
    }

    func prepareEncoderForTestTypeAsAttribute() {
        encoderOptions = XMLEncoderOptions(
            nodeEncodingStrategy: XMLEncoder.NodeEncodingStrategy.custom { _, _ in { _ in .attribute }},
            outputFormatting: XMLEncoder.OutputFormatting.prettyPrinted, rootKey: "container"
        )
        encoder = XMLEncoder(options: encoderOptions)
    }

    func getCodingSimpleTypeFailureMessage<T>(type: T, context: CodingSimpleTypeContext, representation: CodingSimpleTypeRepresentation) -> String {
        return "\(context.rawValue) \(String(describing: T.self)) as \(representation.rawValue) failed"
    }

    enum CodingSimpleTypeContext: String {
        case encoding = "Encoding"
        case decoding = "Decoding"
    }

    enum CodingSimpleTypeRepresentation: String {
        case attribute = "Attribute"
        case element = "Element"
    }

    func getSimpleXMLContainerString(value: String, representation: CodingSimpleTypeRepresentation) -> String {
        var xmlString: String
        switch representation {
        case .attribute:
            xmlString =
                """
                <container value="\(value)" />
                """
        case .element:
            xmlString =
                """
                <container>
                    <value>\(value)</value>
                </container>
                """
        }
        return xmlString
    }
}
