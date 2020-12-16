/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class XMLKeyBasedContainerTests: XCTestCase {

    let box = XMLKeyBasedContainer(
        elements: [("foo", XMLStringContainer("bar")), ("baz", XMLIntContainer(42))] as [(String, XMLContainer)],
        attributes: [("baz", XMLStringContainer("blee"))]
    )

    func testIsNull() {
        let box = XMLKeyBasedContainer()
        XCTAssertEqual(box.isNull, false)
    }

    func testUnbox() {
        let (elements, attributes) = box.unboxed

        XCTAssertEqual(elements.count, 2)
        XCTAssertEqual(elements["foo"].first as? XMLStringContainer, XMLStringContainer("bar"))
        XCTAssertEqual(elements["baz"].first as? XMLIntContainer, XMLIntContainer(42))

        XCTAssertEqual(attributes.count, 1)
        XCTAssertEqual(attributes["baz"].first as? XMLStringContainer, XMLStringContainer("blee"))
    }

    func testXMLString() {
        XCTAssertEqual(box.xmlString, nil)
    }

    func testDescription() {
        XCTAssertEqual(
            box.description,
            "{attributes: [\"baz\": blee], elements: [\"foo\": bar, \"baz\": 42]}"
        )
    }

    func testSequence() {
        var sortedElements: [(String, XMLContainer)] = Array(box.elements)
        sortedElements.sort { $0.0 < $1.0 }

        XCTAssertEqual(sortedElements[0].0, "baz")
        XCTAssertEqual(sortedElements[1].0, "foo")
    }

    func testSubscript() {
        let elements: [(String, XMLContainer)] = [("foo", XMLStringContainer("bar")), ("baz", XMLIntContainer(42))]
        var box = XMLKeyBasedContainer(
            elements: elements,
            attributes: [("baz", XMLStringContainer("blee"))]
        )
        box.elements.append(XMLNullContainer(), at: "bar")
        XCTAssertEqual(box.elements.count, 3)
        XCTAssertEqual(box.elements["bar"].first as? XMLNullContainer, XMLNullContainer())
    }
}
