//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SmithyXML

class ReaderTests: XCTestCase {
    let xmlData = Data("""
<a xmlns=\"https://abc.def.com\">
    <a1 d=\"def\">x</a1>
    <a2 xmlns:a2abc=\"https://def.ghi.com\" e=\"efg\">y</a2>
    <a3>z</a3>
</a>
""".utf8)

    func test_readsRootNode() throws {
        let reader = try Reader.from(data: xmlData)

        XCTAssertEqual(reader.nodeInfo.name, "a")
    }

    func test_readsChildNodes() throws {
        let reader = try Reader.from(data: xmlData)

        XCTAssertEqual(reader.children.count, 3)
        XCTAssertEqual(reader.children.map { $0.nodeInfo.name }, ["a1", "a2", "a3"])
        XCTAssert(reader.children.allSatisfy { $0.nodeInfo.location == .element })
        XCTAssertEqual(reader.children.map { $0.content }, ["x", "y", "z"])
    }

    func test_readsAttributes() throws {
        let reader = try Reader.from(data: xmlData)

        let a1 = reader.children[0]
        XCTAssertEqual(a1.children.first?.nodeInfo.location, .attribute)
        XCTAssertEqual(a1.children.first?.nodeInfo.name, "d")
        XCTAssertEqual(a1.children.first?.content, "def")

        let a2 = reader.children[1]
        XCTAssertEqual(a2.children.first?.nodeInfo.location, .attribute)
        XCTAssertEqual(a2.children.first?.nodeInfo.name, "e")
        XCTAssertEqual(a2.children.first?.content, "efg")
    }

    func test_readsRootNamespace() throws {
        let reader = try Reader.from(data: xmlData)

        XCTAssertEqual(reader.nodeInfo.namespaceDef, .init(prefix: "", uri: "https://abc.def.com"))
        XCTAssertEqual(reader.children.count, 3)
    }

    func test_readsSubNamespace() throws {
        let reader = try Reader.from(data: xmlData)

        XCTAssertEqual(reader.children[1].nodeInfo.namespaceDef, .init(prefix: "a2abc", uri: "https://def.ghi.com"))
        XCTAssertEqual(reader.children.count, 3)
    }
}
