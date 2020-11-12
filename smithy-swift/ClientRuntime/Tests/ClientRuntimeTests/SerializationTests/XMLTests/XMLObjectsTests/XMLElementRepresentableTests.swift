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
