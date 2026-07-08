//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Smithy
@_spi(SmithyReadWrite) import SmithyReadWrite
import SmithyTestUtil
@testable @_spi(SmithyReadWrite) import SmithyJSON

class DocumentTests: XCTestCase {
    let json1: [String : Any] = [
        "list": [1, 2, 3],
        "map": ["a": 1, "b": 2, "c": 3],
        "string": "potato",
        "integer": 1,
        "decimal": 1.5,
        "boolean": false,
        "null": NSNull()
    ]
    lazy var json1Data: Data = { try! JSONSerialization.data(withJSONObject: json1) }()
    lazy var json1Document = { try! Document.make(from: json1) }()

    lazy var json2: [String: Any] = {
        var json2 = json1
        json2["string2"] = "tomato"
        return json2
    }()
    lazy var json2Data: Data = { try! JSONSerialization.data(withJSONObject: json2) }()
    lazy var json2Document = { try! Document.make(from: json2) }()

    func test_encode_encodesJSON() throws {

        // Create a Smithy document from the JSON object
        let document = try Document.make(from: json1)

        // Write the JSON to a JSON writer.
        let writer = SmithyJSON.Writer(nodeInfo: "")
        try writer.write(document)
        let encodedJSONData = try writer.data()

        // Check that the written JSON is equal, using the JSON comparator.
        try XCTAssert(JSONComparator.jsonData(json1Data, isEqualTo: encodedJSONData))
    }

    func test_decode_decodesJSON() throws {

        // Create a reader with the Smithy JSON data
        let reader = try SmithyJSON.Reader.from(data: json1Data)

        // Decode a Document from the JSON
        let decodedJSONDocument: Document = try reader.read()

        // Compare equality of the two documents
        XCTAssertEqual(json1Document, decodedJSONDocument)
    }

    func test_compare_comparesEqualJSON() throws {
        let reader1 = try SmithyJSON.Reader.from(data: json1Data)
        let decodedDoc1: Document = try reader1.read()

        let reader2 = try SmithyJSON.Reader.from(data: json1Data)
        let decodedDoc2: Document = try reader2.read()

        XCTAssertEqual(decodedDoc1, decodedDoc2)
    }

    func test_compare_comparesUnequalJSON() throws {
        let reader1 = try SmithyJSON.Reader.from(data: json1Data)
        let decodedDoc1: Document = try reader1.read()

        let reader2 = try SmithyJSON.Reader.from(data: json2Data)
        let decodedDoc2: Document = try reader2.read()

        XCTAssertNotEqual(decodedDoc1, decodedDoc2)
    }
}
