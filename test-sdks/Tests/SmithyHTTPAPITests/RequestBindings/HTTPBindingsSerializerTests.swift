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

        XCTAssertNil(try subject.data)
        XCTAssertNil(subject.mediaType)
    }

    // MARK: - Headers

    // Explicit `@httpHeader` bindings and `@httpPrefixHeaders` entries both appear when their names
    // don't collide, and neither is included in the body.
    func test_headerAndPrefixHeaders_noCollision_mergesBoth() throws {
        let operation = HTTPBindingsClient.headerAndPrefixHeadersOperation
        let input = HeaderAndPrefixHeadersInput(
            body: "abc",
            prefixHeaders: ["X-Foo": "Foo"],
            specific: "Specific"
        )

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(
            subject.headers,
            Headers(["X-Specific": "Specific", "X-Foo": "Foo", "Content-Type": "application/json"])
        )
        XCTAssertEqual(try subject.data, Data(#"{"body":"abc"}"#.utf8))
    }

    // When a `@httpPrefixHeaders` entry resolves to the name of an explicit `@httpHeader` binding,
    // the header binding wins and the colliding entry is dropped.  The prefix-bound member is
    // serialized before the header-bound one here, so the merge cannot depend on member order.
    func test_headerAndPrefixHeaders_collision_headerWinsAndPrefixEntryDropped() throws {
        let operation = HTTPBindingsClient.headerAndPrefixHeadersOperation
        let input = HeaderAndPrefixHeadersInput(
            prefixHeaders: ["X-Specific": "dropped", "X-Kept": "yes"],
            specific: "fromHeader"
        )

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(
            subject.headers,
            Headers(["X-Specific": "fromHeader", "X-Kept": "yes", "Content-Type": "application/json"])
        )
    }

    // A colliding name is matched case-insensitively, as HTTP header names are.
    func test_headerAndPrefixHeaders_collisionInDifferentCase_headerStillWins() throws {
        let operation = HTTPBindingsClient.headerAndPrefixHeadersOperation
        let input = HeaderAndPrefixHeadersInput(
            prefixHeaders: ["x-specific": "dropped"],
            specific: "fromHeader"
        )

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(
            subject.headers,
            Headers(["X-Specific": "fromHeader", "Content-Type": "application/json"])
        )
    }

    // Merging prefix headers into the explicit headers must not accumulate into the header
    // serializer, so the headers are the same no matter how many times they are read.
    func test_headerAndPrefixHeaders_headersAreStableAcrossReads() throws {
        let operation = HTTPBindingsClient.headerAndPrefixHeadersOperation
        let input = HeaderAndPrefixHeadersInput(prefixHeaders: ["X-Foo": "Foo"], specific: "Specific")

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(subject.headers, subject.headers)
        XCTAssertEqual(
            subject.headers,
            Headers(["X-Specific": "Specific", "X-Foo": "Foo", "Content-Type": "application/json"])
        )
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

    // MARK: - URI

    // An operation with no literal query string in its URI produces no query items of its own.
    func test_uri_withNoLiteralQuery() throws {
        let operation = HTTPBindingsClient.allBoundMembersOperation
        let input = AllBoundMembersInput(a: "a b/c")

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(subject.uri, "/AllBoundMembers/a%20b%2Fc/")
        XCTAssertEqual(subject.queryItems, [])
    }

    // The literal query string is not part of the path, and labels in the path are still substituted.
    func test_uri_withLiteralQuery_splitsPathFromQuery() throws {
        let operation = HTTPBindingsClient.literalQueryOperation
        let input = LiteralQueryInput(name: "a b")

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(subject.uri, "/LiteralQuery/a%20b")
        XCTAssertEqual(subject.queryItems, [
            URIQueryItem(name: "x-id", value: "Literal"),
            URIQueryItem(name: "uploads", value: nil),
        ])
    }

    // A label whose value contains a `?` must not be mistaken for the start of the query string.
    func test_uri_withLabelValueContainingQuestionMark() throws {
        let operation = HTTPBindingsClient.literalQueryOperation
        let input = LiteralQueryInput(name: "a?b")

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(subject.uri, "/LiteralQuery/a%3Fb")
        XCTAssertEqual(subject.queryItems, [
            URIQueryItem(name: "x-id", value: "Literal"),
            URIQueryItem(name: "uploads", value: nil),
        ])
    }

    // MARK: - Literal query items

    // Literal names & values are sent exactly as they appear in the model; they are neither
    // percent-decoded nor re-encoded.  A literal with no value gets a `nil` value, which is
    // rendered without a `=`.
    func test_literalQuery_itemsAreSentVerbatim() throws {
        let operation = HTTPBindingsClient.verbatimLiteralQueryOperation
        let input = VerbatimLiteralQueryInput()

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(subject.uri, "/VerbatimLiteralQuery")
        XCTAssertEqual(subject.queryItems, [
            URIQueryItem(name: "plus", value: "a+b"),
            URIQueryItem(name: "encoded", value: "a%20b"),
            URIQueryItem(name: "flag", value: nil),
        ])
    }

    // Literal query items come first, then explicit `@httpQuery` items, then `@httpQueryParams`.
    func test_literalQuery_mergesWithQueryAndQueryParams() throws {
        let operation = HTTPBindingsClient.literalQueryOperation
        let input = LiteralQueryInput(name: "n", params: ["Extra": "x"], words: ["a", "b"])

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(subject.queryItems, [
            URIQueryItem(name: "x-id", value: "Literal"),
            URIQueryItem(name: "uploads", value: nil),
            URIQueryItem(name: "Word", value: "a"),
            URIQueryItem(name: "Word", value: "b"),
            URIQueryItem(name: "Extra", value: "x"),
        ])
    }

    // A `@httpQueryParams` key that collides with a literal query name is dropped, just as it is
    // when it collides with an explicit `@httpQuery` name.
    func test_literalQuery_collidingQueryParamsEntriesAreDropped() throws {
        let operation = HTTPBindingsClient.literalQueryOperation
        let input = LiteralQueryInput(
            name: "n",
            params: ["x-id": "dropped", "uploads": "dropped", "Kept": "yes"]
        )

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(subject.queryItems, [
            URIQueryItem(name: "x-id", value: "Literal"),
            URIQueryItem(name: "uploads", value: nil),
            URIQueryItem(name: "Kept", value: "yes"),
        ])
    }

    // Query items are the same no matter how many times they are read.
    func test_literalQuery_itemsAreStableAcrossReads() throws {
        let operation = HTTPBindingsClient.literalQueryOperation
        let input = LiteralQueryInput(name: "n", words: ["a"])

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(subject.queryItems, subject.queryItems)
        XCTAssertEqual(subject.uri, subject.uri)
    }
}
