//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SmithyDocumentImpl)
@_spi(SchemaBasedSerde)
import Smithy
@_spi(SchemaBasedSerde)
import SmithyHTTPAPI
@_spi(SchemaBasedSerde)
import SmithySerialization
@_spi(SchemaBasedSerde)
import HTTPPayloadTestSDK

final class HTTPPayloadSerializerTests: XCTestCase {

    // Technically @httpPayload supports all types, but it is only defined for these 5 types
    // (structure, union, document, string, blob) in RestJSON1 & RestXML

    func test_structure_rendersStructurePayload() throws {
        let operation = HTTPPayloadClient.structureHTTPPayloadOperation
        let input = StructureHTTPPayloadInput(payload: .init(a: "xyz", b: 321, c: true))

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation, contentType: "application/json")
        try input.serialize(subject)

        XCTAssertEqual(try subject.data, Data(#"{"a":"xyz","b":321,"c":true}"#.utf8))
    }

    func test_union_rendersUnionPayload() throws {
        let operation = HTTPPayloadClient.unionHTTPPayloadOperation
        let input = UnionHTTPPayloadInput(payload: .b(456))

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation, contentType: "application/json")
        try input.serialize(subject)

        XCTAssertEqual(try subject.data, Data(#"{"b":456}"#.utf8))
    }

    func test_document_rendersDocumentPayload() throws {
        let operation = HTTPPayloadClient.documentHTTPPayloadOperation
        let document: Document = [
            "a": ["b", "c", "d"]
        ]
        let input = DocumentHTTPPayloadInput(payload: document)

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation, contentType: "application/json")
        try input.serialize(subject)

        XCTAssertEqual(try subject.data, Data(#"{"a":["b","c","d"]}"#.utf8))
    }

    func test_string_rendersStringPayload() throws {
        let justAString = "justastring"
        let operation = HTTPPayloadClient.stringHTTPPayloadOperation
        let input = StringHTTPPayloadInput(payload: justAString)

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation, contentType: "application/json")
        try input.serialize(subject)

        XCTAssertEqual(try subject.data, Data(justAString.utf8))
    }

    func test_blob_rendersBlobPayload() throws {
        let justABlob = Data("justablob".utf8)
        let operation = HTTPPayloadClient.blobHTTPPayloadOperation
        let input = BlobHTTPPayloadInput(payload: justABlob)

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation, contentType: "application/json")
        try input.serialize(subject)

        XCTAssertEqual(try subject.data, justABlob)
    }
}
