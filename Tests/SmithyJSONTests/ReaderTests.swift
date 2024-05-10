//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SmithyJSON

class ReaderTests: XCTestCase {

    func test_readsNil() async throws {
        let jsonData = Data()
        let reader = try SmithyJSON.Reader.from(data: jsonData)
        XCTAssertEqual(reader.jsonNode, nil)
    }

    func test_readsAJSONObject() async throws {
        let jsonData = Data("""
        { "property": "potato" }
        """.utf8)
        let reader = try SmithyJSON.Reader.from(data: jsonData)
        XCTAssertEqual(reader.children.count, 1)
        XCTAssertEqual(try reader["property"].readIfPresent(), "potato")
    }
}
