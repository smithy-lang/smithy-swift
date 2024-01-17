//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SmithyXML

class NodeInfoTests: XCTestCase {
    
    func test_init_splitsName() {
        let subject = NodeInfo("abc:def")
        XCTAssertEqual(subject.prefix, "abc")
        XCTAssertEqual(subject.name, "def")
    }

    func test_init_hasNilPrefixWhenNameIsUnprefixed() {
        let subject = NodeInfo("def")
        XCTAssertEqual(subject.prefix, "")
        XCTAssertEqual(subject.name, "def")
    }

    func test_init_resolvesNamespace() {
        let subject = NodeInfo("abc:def", namespace: .init(prefix: "abc", uri: "https://xctest.com/"))
        XCTAssertEqual(subject.prefix, "abc")
        XCTAssertEqual(subject.name, "def")
    }
}
