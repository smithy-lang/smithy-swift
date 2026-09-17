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

// Tests that `HTTPPrefixHeadersSerializer` implements the behavior defined for the `httpPrefixHeaders` trait:
// https://smithy.io/2.0/spec/http-bindings.html#httpprefixheaders-trait
final class HTTPPrefixHeadersSerializerTests: XCTestCase {

    // MARK: - non-empty prefix

    func test_prefixed_serializesEachEntryUnderItsPrefixedKey() throws {
        let operation = HTTPPrefixHeadersClient.prefixedHTTPPrefixHeadersOperation
        let subject = HTTPPrefixHeadersSerializer()

        // The trait's prefix is prepended to the map key to form the header name.
        let input = PrefixedHTTPPrefixHeadersInput(headers: ["Abc": "Abc value"])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Foo-Abc"), ["Abc value"])
    }

    func test_prefixed_serializesMultipleEntries() throws {
        let operation = HTTPPrefixHeadersClient.prefixedHTTPPrefixHeadersOperation
        let subject = HTTPPrefixHeadersSerializer()

        let input = PrefixedHTTPPrefixHeadersInput(headers: ["Abc": "Abc value", "Def": "Def value"])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers, Headers([
            "X-Foo-Abc": "Abc value",
            "X-Foo-Def": "Def value",
        ]))
    }

    func test_prefixed_serializesValueVerbatimWithoutQuoting() throws {
        let operation = HTTPPrefixHeadersClient.prefixedHTTPPrefixHeadersOperation
        let subject = HTTPPrefixHeadersSerializer()

        // A map value is a scalar string, not a list element, so it is never quoted even if it
        // contains characters that would require quoting inside a list value.
        let input = PrefixedHTTPPrefixHeadersInput(headers: ["Abc": "a,b (c)"])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Foo-Abc"), ["a,b (c)"])
    }

    func test_prefixed_serializesEmptyValue() throws {
        let operation = HTTPPrefixHeadersClient.prefixedHTTPPrefixHeadersOperation
        let subject = HTTPPrefixHeadersSerializer()

        let input = PrefixedHTTPPrefixHeadersInput(headers: ["Abc": ""])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Foo-Abc"), [""])
    }

    func test_prefixed_emptyMapProducesNoHeaders() throws {
        let operation = HTTPPrefixHeadersClient.prefixedHTTPPrefixHeadersOperation
        let subject = HTTPPrefixHeadersSerializer()

        let input = PrefixedHTTPPrefixHeadersInput(headers: [:])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertTrue(subject.headers.isEmpty)
    }

    func test_prefixed_omittedMapProducesNoHeaders() throws {
        let operation = HTTPPrefixHeadersClient.prefixedHTTPPrefixHeadersOperation
        let subject = HTTPPrefixHeadersSerializer()

        let input = PrefixedHTTPPrefixHeadersInput()
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertTrue(subject.headers.isEmpty)
    }

    // MARK: - empty prefix

    func test_emptyPrefix_serializesEachKeyAsTheHeaderNameUnchanged() throws {
        let operation = HTTPPrefixHeadersClient.emptyPrefixHTTPPrefixHeadersOperation
        let subject = HTTPPrefixHeadersSerializer()

        // With an empty prefix, the map key is the header name.
        let input = EmptyPrefixHTTPPrefixHeadersInput(headers: ["X-Foo": "Foo", "Hello": "Hello"])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers, Headers(["X-Foo": "Foo", "Hello": "Hello"]))
    }

    // MARK: - other bindings

    func test_headerBoundMemberIsNotSerialized() throws {
        let operation = HTTPPrefixHeadersClient.headerAndEmptyPrefixHTTPPrefixHeadersOperation
        let subject = HTTPPrefixHeadersSerializer()

        // Only the member bound with `httpPrefixHeaders` is serialized here; a member bound with
        // `httpHeader` is the header serializer's to write.
        let input = HeaderAndEmptyPrefixHTTPPrefixHeadersInput(
            headers: ["X-Foo": "Foo"],
            specific: "Specific"
        )
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers, Headers(["X-Foo": "Foo"]))
    }
}
