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
@testable import HTTPPrefixHeadersTestSDK

// Tests that `HTTPPrefixHeadersDeserializer` implements the behavior defined for the `httpPrefixHeaders` trait:
// https://smithy.io/2.0/spec/http-bindings.html#httpprefixheaders-trait
final class HTTPPrefixHeadersDeserializerTests: XCTestCase {

    // MARK: - non-empty prefix

    func test_prefixed_deserializesMatchingHeadersWithThePrefixRemoved() throws {
        let headers = Headers(["X-Foo-Abc": "Abc value", "X-Foo-Def": "Def value"])

        let output = try prefixedOutput(headers)

        XCTAssertEqual(output.headers, ["Abc": "Abc value", "Def": "Def value"])
    }

    func test_prefixed_omitsHeadersThatDoNotStartWithThePrefix() throws {
        // `X-Foo` does not start with `X-Foo-`, so it is not part of the map, and neither is a
        // header that shares no prefix at all.
        let headers = Headers(["X-Foo-Abc": "Abc value", "X-Foo": "Foo", "X-Bar": "Bar"])

        let output = try prefixedOutput(headers)

        XCTAssertEqual(output.headers, ["Abc": "Abc value"])
    }

    func test_prefixed_matchesThePrefixCaseInsensitively() throws {
        // HTTP header names are case-insensitive, and their case is not guaranteed to survive
        // transit, so the prefix is matched without regard to case.  The rest of the name becomes
        // the map key in the case it was received.
        let headers = Headers(["x-foo-Abc": "Abc value"])

        let output = try prefixedOutput(headers)

        XCTAssertEqual(output.headers, ["Abc": "Abc value"])
    }

    func test_prefixed_deserializesEmptyValue() throws {
        let headers = Headers(["X-Foo-Abc": ""])

        let output = try prefixedOutput(headers)

        XCTAssertEqual(output.headers, ["Abc": ""])
    }

    func test_prefixed_combinesRepeatedHeaderIntoOneCommaDelimitedValue() throws {
        let headers = Headers(["X-Foo-Abc": ["one", "two"]])

        let output = try prefixedOutput(headers)

        XCTAssertEqual(output.headers, ["Abc": "one,two"])
    }

    func test_prefixed_noMatchingHeadersProducesAnEmptyMap() throws {
        // The map is set to an empty map, not left nil, so that a caller can tell a response with
        // no prefixed headers from one that was never deserialized.
        let output = try prefixedOutput(Headers(["X-Bar": "Bar"]))

        XCTAssertEqual(output.headers, [:])
    }

    func test_prefixed_noHeadersAtAllProducesAnEmptyMap() throws {
        let output = try prefixedOutput(Headers())

        XCTAssertEqual(output.headers, [:])
    }

    // MARK: - empty prefix

    func test_emptyPrefix_deserializesEveryHeaderWithItsNameUnchanged() throws {
        let operation = HTTPPrefixHeadersClient.emptyPrefixHTTPPrefixHeadersOperation
        let subject = HTTPPrefixHeadersDeserializer(headers: Headers(["X-Foo": "Foo", "Hello": "Hello"]))

        var output = EmptyPrefixHTTPPrefixHeadersOutput()
        try subject.readStruct(operation.outputSchema, &output)

        XCTAssertEqual(output.headers, ["X-Foo": "Foo", "Hello": "Hello"])
    }

    // MARK: - other bindings

    func test_headerBoundMemberIsAlsoCollectedIntoTheMap() throws {
        let operation = HTTPPrefixHeadersClient.headerAndEmptyPrefixHTTPPrefixHeadersOperation
        let subject = HTTPPrefixHeadersDeserializer(headers: Headers(["X-Specific": "Foo", "Hello": "Hello"]))

        var output = HeaderAndEmptyPrefixHTTPPrefixHeadersOutput()
        try subject.readStruct(operation.outputSchema, &output)

        // Unlike serialization, deserialization gives the `httpHeader` binding no precedence: a
        // header matching the prefix is collected into the map even when it is also bound to a
        // member with `httpHeader`.
        XCTAssertEqual(output.headers, ["X-Specific": "Foo", "Hello": "Hello"])

        // Only the prefix-bound member is filled by this deserializer.
        XCTAssertNil(output.specific)
    }

    // MARK: - Private methods

    private func prefixedOutput(_ headers: Headers) throws -> PrefixedHTTPPrefixHeadersOutput {
        let operation = HTTPPrefixHeadersClient.prefixedHTTPPrefixHeadersOperation
        let subject = HTTPPrefixHeadersDeserializer(headers: headers)

        var output = PrefixedHTTPPrefixHeadersOutput()
        try subject.readStruct(operation.outputSchema, &output)
        return output
    }
}
