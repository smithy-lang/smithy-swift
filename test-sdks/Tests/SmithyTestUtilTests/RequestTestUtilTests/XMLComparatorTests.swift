//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyTestUtil
import XCTest

class XMLComparatorTests: XCTestCase {

    func test_compare_namespacesMustBeEqual() {
        let xml1 = "<a xmlns:abc=\"https://xctest.com/\"/>"
        let xml2 = "<a xmlns:def=\"https://xctest.com/\"/>"

        XCTAssertFalse(XMLComparator.xmlData(xml1.data, isEqualTo: xml2.data))
    }

    func test_compare_resolvesDefinedNamespaces() {
        let xml1 = "<a xmlns:abc=\"https://xctest.com/\" abc:attrKey=\"attrValue\"></a>"
        let xml2 = "<a xmlns:abc=\"https://xctest.com/\" attrKey=\"attrValue\"></a>"

        XCTAssertTrue(XMLComparator.xmlData(xml1.data, isEqualTo: xml2.data))
    }

    func test_compare_doesNotResolveUndefinedNamespaces() {
        let xml1 = "<a xmlns:abc=\"https://xctest.com/\" def:attrKey=\"attrValue\"></a>"
        let xml2 = "<a xmlns:abc=\"https://xctest.com/\" attrKey=\"attrValue\"></a>"

        XCTAssertFalse(XMLComparator.xmlData(xml1.data, isEqualTo: xml2.data))
    }

    func test_compare_differentElementOrdersAreEqual() {
        let xml1 = "<a><a1/><a2/></a>"
        let xml2 = "<a><a2/><a1/></a>"

        XCTAssertTrue(XMLComparator.xmlData(xml1.data, isEqualTo: xml2.data))
    }
}

private extension String {
    var data: Data { Data(utf8) }
}
