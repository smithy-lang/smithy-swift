//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Smithy
import SmithyTestUtil
@testable @_spi(SmithyReadWrite) import SmithyJSON

class DocumentTests: XCTestCase {
    let json: [String : Any] = [
        "list": [1, 2, 3],
        "map": ["a": 1, "b": 2, "c": 3],
        "string": "potato",
        "integer": 1,
        "decimal": 1.5,
        "boolean": false,
        "null": NSNull()
    ]
    lazy var jsonData: Data = { try! JSONSerialization.data(withJSONObject: json) }()
    lazy var jsonDocument = { try! DocumentContainer.make(from: json) }()

    func test_encode_encodesJSON() throws {

        // Create a Smithy document from the JSON object
        let document = try DocumentContainer.make(from: json)

        // Write the JSON to a JSON writer.
        let writer = SmithyJSON.Writer(nodeInfo: "")
        try writer.write(document)
        let encodedJSONData = try writer.data()

        // Check that the written JSON is equal, using the JSON comparator.
        try XCTAssert(JSONComparator.jsonData(jsonData, isEqualTo: encodedJSONData))
    }

    func test_decode_decodesJSON() throws {
        let reader = try SmithyJSON.Reader.from(data: jsonData)
        let decodedJSONDocument = try reader.readIfPresent().map { DocumentContainer(document: $0) }

        XCTAssertEqual(jsonDocument, decodedJSONDocument)
    }
}
