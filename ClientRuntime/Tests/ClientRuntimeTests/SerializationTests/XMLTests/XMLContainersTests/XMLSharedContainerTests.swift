/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class XMLSharedContainerTests: XCTestCase {

    func testInit() {
        let box = XMLSharedContainer(XMLBoolContainer(false))
        box.withShared { shared in
            XCTAssertFalse(shared.unboxed)
        }
    }

    func testIsNull() {
        let box = XMLSharedContainer(XMLBoolContainer(false))
        XCTAssertEqual(box.isNull, false)
    }

    func testXMLString() {
        let nullBox = XMLNullContainer()
        let sharedNullBox = XMLSharedContainer(nullBox)
        XCTAssertEqual(sharedNullBox.xmlString, nullBox.xmlString)

        let boolBox = XMLBoolContainer(false)
        let sharedBoolBox = XMLSharedContainer(boolBox)
        XCTAssertEqual(sharedBoolBox.xmlString, boolBox.xmlString)

        let intBox = XMLIntContainer(42)
        let sharedIntBox = XMLSharedContainer(intBox)
        XCTAssertEqual(sharedIntBox.xmlString, intBox.xmlString)

        let stringBox = XMLStringContainer("lorem ipsum")
        let sharedStringBox = XMLSharedContainer(stringBox)
        XCTAssertEqual(sharedStringBox.xmlString, stringBox.xmlString)
    }

    func testWithShared() {
        let sharedBox = XMLSharedContainer(XMLArrayBasedContainer())
        let sharedBoxAlias = sharedBox

        XCTAssertEqual(sharedBox.withShared { $0.count }, 0)
        XCTAssertEqual(sharedBoxAlias.withShared { $0.count }, 0)

        sharedBox.withShared { unkeyedBox in
            unkeyedBox.append(XMLNullContainer())
        }

        XCTAssertEqual(sharedBox.withShared { $0.count }, 1)
        XCTAssertEqual(sharedBoxAlias.withShared { $0.count }, 1)

        sharedBoxAlias.withShared { unkeyedBox in
            unkeyedBox.append(XMLNullContainer())
        }

        XCTAssertEqual(sharedBox.withShared { $0.count }, 2)
        XCTAssertEqual(sharedBoxAlias.withShared { $0.count }, 2)
    }
}
