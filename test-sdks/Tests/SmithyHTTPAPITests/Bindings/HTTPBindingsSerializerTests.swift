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
import HTTPBindingsTestSDK

final class HTTPBindingsSerializerTests: XCTestCase {

    func test_allUnboundMembers_allGetSerializedToBody() throws {
        let operation = HTTPBindingsClient.allUnboundMembersOperation
        let input = AllUnboundMembersInput(a: "xyz", b: 321, c: true)

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(try subject.data, Data(#"{"a":"xyz","b":321,"c":true}"#.utf8))
    }

    func test_allBoundMembers_noneGetSerializedToBody() throws {
        let operation = HTTPBindingsClient.allBoundMembersOperation
        let input = AllBoundMembersInput(a: "xyz", b: 321, c: true)

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(try subject.data, Data(#"{}"#.utf8))
    }

    // MARK: - Query items

    // A list-valued `@httpQuery` member must produce one query item per element, in order.
    // (Regression: the query/query-params merge previously collapsed repeated names to one value.)
    func test_queryList_preservesAllRepeatedValues() throws {
        let operation = HTTPBindingsClient.queryAndQueryParamsOperation
        let input = QueryAndQueryParamsInput(words: ["a", "b", "c"])

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(subject.queryItems, [
            URIQueryItem(name: "Word", value: "a"),
            URIQueryItem(name: "Word", value: "b"),
            URIQueryItem(name: "Word", value: "c"),
        ])
    }

    // With no name collision, explicit `@httpQuery` items and `@httpQueryParams` entries both appear,
    // with the explicit query items first.
    func test_queryAndQueryParams_noCollision_mergesBoth() throws {
        let operation = HTTPBindingsClient.queryAndQueryParamsOperation
        let input = QueryAndQueryParamsInput(params: ["Extra": "x"], words: ["a", "b"])

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(subject.queryItems, [
            URIQueryItem(name: "Word", value: "a"),
            URIQueryItem(name: "Word", value: "b"),
            URIQueryItem(name: "Extra", value: "x"),
        ])
    }

    // When a `@httpQueryParams` key collides with an explicit list-valued `@httpQuery` name, the query
    // binding wins: all of its repeated values are kept and the colliding params entry is dropped,
    // while non-colliding params entries are retained.
    func test_queryAndQueryParams_collision_queryWinsAndParamsEntryDropped() throws {
        let operation = HTTPBindingsClient.queryAndQueryParamsOperation
        let input = QueryAndQueryParamsInput(params: ["Word": "dropped", "Kept": "yes"], words: ["a", "b"])

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(subject.queryItems, [
            URIQueryItem(name: "Word", value: "a"),
            URIQueryItem(name: "Word", value: "b"),
            URIQueryItem(name: "Kept", value: "yes"),
        ])
    }

    // A scalar `@httpQuery` binding also takes precedence over a colliding `@httpQueryParams` key.
    func test_scalarQueryAndQueryParams_collision_queryWins() throws {
        let operation = HTTPBindingsClient.scalarQueryAndQueryParamsOperation
        let input = ScalarQueryAndQueryParamsInput(key: "fromQuery", params: ["Key": "dropped", "Kept": "yes"])

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(subject.queryItems, [
            URIQueryItem(name: "Key", value: "fromQuery"),
            URIQueryItem(name: "Kept", value: "yes"),
        ])
    }
}
