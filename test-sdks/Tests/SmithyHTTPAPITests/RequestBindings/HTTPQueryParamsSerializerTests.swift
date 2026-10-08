//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SchemaBasedSerde)
import Smithy
@_spi(SchemaBasedSerde)
import SmithyHTTPAPI
@_spi(SchemaBasedSerde)
import SmithySerialization
@_spi(SchemaBasedSerde)
@testable import HTTPQueryParamsTestSDK

// Tests that `HTTPQueryParamsSerializer` implements the behavior defined for the `httpQueryParams` trait:
// https://smithy.io/2.0/spec/http-bindings.html#httpqueryparams-trait
final class HTTPQueryParamsSerializerTests: XCTestCase {

    // MARK: - map of string

    func test_stringMap_serializesEachEntryUsingItsKeyAsTheQueryName() throws {
        let operation = HTTPQueryParamsTestSDK.HTTPQueryParamsClient.stringMapHTTPQueryParamsOperation
        let subject = HTTPQueryParamsSerializer()

        let input = StringMapHTTPQueryParamsInput(params: ["Key": "Value"])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "Key", value: "Value")])
    }

    func test_stringMap_serializesMultipleEntries() throws {
        let operation = HTTPQueryParamsTestSDK.HTTPQueryParamsClient.stringMapHTTPQueryParamsOperation
        let subject = HTTPQueryParamsSerializer()

        // A map has no defined ordering, so compare as an unordered set.
        let input = StringMapHTTPQueryParamsInput(params: ["A": "1", "B": "2"])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(Set(subject.queryItems), Set([
            URIQueryItem(name: "A", value: "1"),
            URIQueryItem(name: "B", value: "2"),
        ]))
    }

    func test_stringMap_percentEncodesKeyAndValue() throws {
        let operation = HTTPQueryParamsTestSDK.HTTPQueryParamsClient.stringMapHTTPQueryParamsOperation
        let subject = HTTPQueryParamsSerializer()

        // Reserved characters in both the parameter name (map key) and value must be percent-encoded.
        let input = StringMapHTTPQueryParamsInput(params: ["a key": "a/b=c"])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "a%20key", value: "a%2Fb%3Dc")])
    }

    func test_stringMap_emptyMapProducesNoQueryItems() throws {
        let operation = HTTPQueryParamsTestSDK.HTTPQueryParamsClient.stringMapHTTPQueryParamsOperation
        let subject = HTTPQueryParamsSerializer()

        let input = StringMapHTTPQueryParamsInput(params: [:])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [])
    }

    func test_stringMap_omittedMapProducesNoQueryItems() throws {
        let operation = HTTPQueryParamsTestSDK.HTTPQueryParamsClient.stringMapHTTPQueryParamsOperation
        let subject = HTTPQueryParamsSerializer()

        let input = StringMapHTTPQueryParamsInput()
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [])
    }

    // MARK: - map of list of string

    func test_listMap_serializesEachListElementAsARepeatedQueryItemUnderItsKey() throws {
        let operation = HTTPQueryParamsTestSDK.HTTPQueryParamsClient.listMapHTTPQueryParamsOperation
        let subject = HTTPQueryParamsSerializer()

        // Each element of a list value repeats the map key as its query name, e.g. `Word=a&Word=b`,
        // preserving element order.
        let input = ListMapHTTPQueryParamsInput(params: ["Word": ["a", "b"]])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [
            URIQueryItem(name: "Word", value: "a"),
            URIQueryItem(name: "Word", value: "b"),
        ])
    }

    func test_listMap_percentEncodesKeyAndEachElement() throws {
        let operation = HTTPQueryParamsTestSDK.HTTPQueryParamsClient.listMapHTTPQueryParamsOperation
        let subject = HTTPQueryParamsSerializer()

        let input = ListMapHTTPQueryParamsInput(params: ["a key": ["a/b", "c d"]])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [
            URIQueryItem(name: "a%20key", value: "a%2Fb"),
            URIQueryItem(name: "a%20key", value: "c%20d"),
        ])
    }

    func test_listMap_emptyListValueProducesNoQueryItems() throws {
        let operation = HTTPQueryParamsTestSDK.HTTPQueryParamsClient.listMapHTTPQueryParamsOperation
        let subject = HTTPQueryParamsSerializer()

        let input = ListMapHTTPQueryParamsInput(params: ["Word": []])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [])
    }

    // MARK: - map of sparse list of string

    func test_sparseListMap_serializesNilElementsAsTheNullLiteral() throws {
        let operation = HTTPQueryParamsTestSDK.HTTPQueryParamsClient.sparseListMapHTTPQueryParamsOperation
        let subject = HTTPQueryParamsSerializer()

        // A sparse list value may contain nil elements; each is serialized as the literal string "null",
        // keeping its position relative to the present elements under the shared query name.
        let input = SparseListMapHTTPQueryParamsInput(params: ["Word": ["a", nil, "b"]])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [
            URIQueryItem(name: "Word", value: "a"),
            URIQueryItem(name: "Word", value: "null"),
            URIQueryItem(name: "Word", value: "b"),
        ])
    }
}
