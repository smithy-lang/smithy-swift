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

        static func write(_ value: HasNestedElements, to writer: Writer) throws {
            try writer[.init("a")].write(value.a)
            try writer[.init("b")].write(value.b)
        }

        let a: String
        let b: String
    }

    func test_encodesXMLWithNestedElements() throws {
        let data = try DocumentWriter().write(HasNestedElements(a: "a", b: "b"), rootElement: "test", valueWriter: HasNestedElements.write(_:to:))
        let xml = "<test><a>a</a><b>b</b></test>"
        try AssertXMLDataEqual(data, Data(xml.utf8))
    }

    private struct HasNestedElementAndAttribute: Encodable {

        static func write(_ value: HasNestedElementAndAttribute, to writer: Writer) throws {
            try writer[.init("a")].write(value.a)
            try writer[.init("b", location: .attribute)].write(value.b)
        }

        let a: String
        let b: String
    }

    func test_encodesXMLWithElementAndAttribute() throws {
        let data = try DocumentWriter().write(HasNestedElementAndAttribute(a: "a", b: "b"), rootElement: "test", valueWriter: HasNestedElementAndAttribute.write(_:to:))
        let xml = "<test b=\"b\"><a>a</a></test>"
        try AssertXMLDataEqual(data, Data(xml.utf8))
    }
}
