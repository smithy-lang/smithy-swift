//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import struct SmithySerde.InvalidEncodingError
@testable @_spi(SmithyReadWrite) import SmithyJSON

final class ReaderTests: XCTestCase {

    func test_readsEmptyDataAsEmptyJSONObject() async throws {
        let jsonData = Data()
        let reader = try SmithyJSON.Reader.from(data: jsonData)
        XCTAssertEqual(reader.jsonNode, .object)
        XCTAssert(reader.children.isEmpty)
    }

    func test_readsAJSONObject() async throws {
        let jsonData = Data("""
        { "property": "potato" }
        """.utf8)
        let reader = try SmithyJSON.Reader.from(data: jsonData)
        XCTAssertEqual(reader.children.count, 1)
        XCTAssertEqual(try reader["property"].readIfPresent(), "potato")
    }

    func test_throwsOnInvalidJSON() async throws {
        let jsonData = Data("""
        { "json": "incomplet    
        """.utf8)
        XCTAssertThrowsError(try SmithyJSON.Reader.from(data: jsonData)) { error in
            XCTAssert(error is InvalidEncodingError)
        }
    }
}
