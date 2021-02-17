/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class XMLElementRepresentableTests: XCTestCase {

    func testTransformToKeyBasedContainer() {
        let fooChild1 = XMLElementRepresentable(
            key: "foo",
            stringValue: "456",
            attributes: [XMLAttributeRepresentable(key: "id", value: "123")]
        )
        let fooChild2 = XMLElementRepresentable(
            key: "foo",
            stringValue: "123",
            attributes: [XMLAttributeRepresentable(key: "id", value: "789")]
        )
        let root = XMLElementRepresentable(
            key: "container",
            elements: [fooChild1, fooChild2],
            attributes: []
        )

        let keyedContainer = root.transformToKeyBasedContainer() as? XMLKeyBasedContainer
        XCTAssertNotNil(keyedContainer)

        let foo = keyedContainer!.elements["foo"]
        XCTAssertNotNil(foo)
        XCTAssertEqual(foo.count, 2)
    }

    func testInitWithKey() {
        let emptyElement = XMLElementRepresentable(key: "foo")

        XCTAssertEqual(emptyElement.key, "foo")
        XCTAssertNil(emptyElement.stringValue)
        XCTAssertEqual(emptyElement.elements, [])
        XCTAssertEqual(emptyElement.attributes, [])
    }

    func testInitWithArrayBasedContainer() {
        let xmlElement = XMLElementRepresentable(key: "foo", isStringBoxCDATA: false, box: XMLArrayBasedContainer())

        XCTAssertEqual(xmlElement.key, "foo")
        XCTAssertNil(xmlElement.stringValue)
        XCTAssertEqual(xmlElement.elements, [])
        XCTAssertEqual(xmlElement.attributes, [])
    }

    func testInitWithKeyBasedContainer() {
        let xmlElement = XMLElementRepresentable(key: "foo", isStringBoxCDATA: false, box: XMLKeyBasedContainer(
            elements: [] as [(String, XMLContainer)],
            attributes: [("baz", XMLNullContainer()), ("blee", XMLIntContainer(42))] as [(String, XMLSimpleContainer)]
        ))

        XCTAssertEqual(xmlElement.key, "foo")
        XCTAssertNil(xmlElement.stringValue)
        XCTAssertEqual(xmlElement.elements, [])
        XCTAssertEqual(xmlElement.attributes, [XMLAttributeRepresentable(key: "blee", value: "42")])
    }

    func testInitWithStringContainer() {
        let xmlElement = XMLElementRepresentable(key: "foo", isStringBoxCDATA: false, box: XMLStringContainer("bar"))
        let xmlStringElement = XMLElementRepresentable(stringValue: "bar")

        XCTAssertEqual(xmlElement.key, "foo")
        XCTAssertNil(xmlElement.stringValue)
        XCTAssertEqual(xmlElement.elements, [xmlStringElement])
        XCTAssertEqual(xmlElement.attributes, [])
    }
}
