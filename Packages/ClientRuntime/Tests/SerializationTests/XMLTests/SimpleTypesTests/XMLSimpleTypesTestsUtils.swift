/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

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
