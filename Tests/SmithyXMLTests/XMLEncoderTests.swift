//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SmithyXML) import SmithyXML

class XMLEncoderTests: XCTestCase {

    private struct HasNestedElements: Encodable {
        let a: String
        let b: String

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: XMLCodingKey.self)
            try container.encode(a, forKey: XMLCodingKey(stringValue: "a"))
            try container.encode(b, forKey: XMLCodingKey(stringValue: "b"))
        }
    }

    func test_encodesXMLWithNestedElements() throws {
        let data = try XMLEncoder().encode(HasNestedElements(a: "a", b: "b"), rootElement: "test")
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><test><a>a</a><b>b</b></test>"
        try AssertXMLDataEqual(data, Data(xml.utf8))
    }

    private struct HasNestedElementAndAttribute: Encodable {
        let a: String
        let b: String

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: XMLCodingKey.self)
            try container.encode(a, forKey: XMLCodingKey(stringValue: "a"))
            try container.encode(b, forKey: XMLCodingKey(stringValue: "b", location: .attribute))
        }
    }

    func test_encodesXMLWithElementAndAttribute() throws {
        let data = try XMLEncoder().encode(HasNestedElementAndAttribute(a: "a", b: "b"), rootElement: "test")
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><test b=\"b\"><a>a</a></test>"
        try AssertXMLDataEqual(data, Data(xml.utf8))
    }
}
