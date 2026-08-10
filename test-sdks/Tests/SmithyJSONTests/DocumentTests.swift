//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SmithyDocumentImpl) import Smithy
@_spi(SmithyReadWrite) import SmithyReadWrite
import SmithyTestUtil
@testable @_spi(SmithyReadWrite) @_spi(SchemaBasedSerde) import SmithyJSON
@_spi(SchemaBasedSerde) import AWSJSONTestSDK

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

    func test_document_writesDocumentListOfLists() throws {
        let input = SerdeOperationInput(
            document: Document(
                ListDocument(
                    value: [
                        ListDocument(value: [StringDocument(value: "1")]),
                        ListDocument(value: [StringDocument(value: "2")]),
                        ListDocument(value: [StringDocument(value: "3")]),
                    ]
                )
            )
        )
        let subject = Serializer(usesJSONNameTrait: false)
        try input.serialize(subject)
        XCTAssertEqual(try subject.data, Data(#"{"document":[["1"],["2"],["3"]]}"#.utf8))
    }

    func test_document_writesDocumentMapOfMaps() throws {
        let input = SerdeOperationInput(
            document: Document(
                StringMapDocument(
                    value: [
                        "1": StringMapDocument(value: ["2": StringDocument(value: "3")]),
                    ]
                )
            )
        )
        let subject = Serializer(usesJSONNameTrait: false)
        try input.serialize(subject)
        XCTAssertEqual(try subject.data, Data(#"{"document":{"1":{"2":"3"}}}"#.utf8))
    }

    func test_document_readsDocumentListOfLists() throws {
        let data = Data(#"{"document":[["1"],["2"],["3"]]}"#.utf8)
        let subject = try Deserializer(usesJSONNameTrait: false, data: data)
        let output = try SerdeOperationOutput.deserialize(subject)
        let list = try output.document?.asList().map { try $0.asList().map { try $0.asString() } }
        XCTAssertEqual(list, [["1"], ["2"], ["3"]])
    }

    func test_document_readsDocumentMapOfMaps() throws {
        let data = Data(#"{"document":{"1":{"2":"3"}}}"#.utf8)
        let subject = try Deserializer(usesJSONNameTrait: false, data: data)
        let output = try SerdeOperationOutput.deserialize(subject)
        let list = try output.document?.asStringMap().mapValues { try $0.asStringMap().mapValues { try $0.asString() } }
        XCTAssertEqual(list, ["1": ["2": "3"]])
    }

    func test_document_readsDocumentListOfListsOfLists() throws {
        let data = Data(#"{"document":[[["1"],["2"]],[["3"]]]}"#.utf8)
        let subject = try Deserializer(usesJSONNameTrait: false, data: data)
        let output = try SerdeOperationOutput.deserialize(subject)
        let list = try output.document?.asList().map { middle in
            try middle.asList().map { inner in
                try inner.asList().map { try $0.asString() }
            }
        }
        XCTAssertEqual(list, [[["1"], ["2"]], [["3"]]])
    }

    func test_document_readsDocumentMapOfMapsOfMaps() throws {
        let data = Data(#"{"document":{"1":{"2":{"3":"4"}}}}"#.utf8)
        let subject = try Deserializer(usesJSONNameTrait: false, data: data)
        let output = try SerdeOperationOutput.deserialize(subject)
        let map = try output.document?.asStringMap().mapValues { middle in
            try middle.asStringMap().mapValues { inner in
                try inner.asStringMap().mapValues { try $0.asString() }
            }
        }
        XCTAssertEqual(map, ["1": ["2": ["3": "4"]]])
    }

    func test_document_readsDocumentMapOfListsOfLists() throws {
        let data = Data(#"{"document":{"a":[["1"],["2"]]}}"#.utf8)
        let subject = try Deserializer(usesJSONNameTrait: false, data: data)
        let output = try SerdeOperationOutput.deserialize(subject)
        let map = try output.document?.asStringMap().mapValues { middle in
            try middle.asList().map { inner in
                try inner.asList().map { try $0.asString() }
            }
        }
        XCTAssertEqual(map, ["a": [["1"], ["2"]]])
    }

    func test_document_readsDocumentListOfMapsOfLists() throws {
        let data = Data(#"{"document":[{"a":["1"]},{"b":["2"]}]}"#.utf8)
        let subject = try Deserializer(usesJSONNameTrait: false, data: data)
        let output = try SerdeOperationOutput.deserialize(subject)
        let list = try output.document?.asList().map { middle in
            try middle.asStringMap().mapValues { inner in
                try inner.asList().map { try $0.asString() }
            }
        }
        XCTAssertEqual(list, [["a": ["1"]], ["b": ["2"]]])
    }
}
