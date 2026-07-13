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
@_spi(SmithyTimestamps)
import struct SmithyTimestamps.TimestampFormatter
@_spi(SchemaBasedSerde)
@testable import HTTPQueryTestSDK

// Tests that `HTTPQuerySerializer` implements the behavior defined for the `httpQuery` trait:
// https://smithy.io/2.0/spec/http-bindings.html#httpquery-trait
final class HTTPQuerySerializerTests: XCTestCase {

    // MARK: - boolean HTTP query

    func test_boolean_serializesBooleanAsTrueOrFalse() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.booleanHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        let input = BooleanHTTPQueryInput(flag: true)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "Flag", value: "true")])
    }

    func test_boolean_serializesFalse() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.booleanHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        let input = BooleanHTTPQueryInput(flag: false)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "Flag", value: "false")])
    }

    // MARK: - numeric HTTP query

    func test_byte_serializesByteIntoQuery() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.byteHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        let input = ByteHTTPQueryInput(value: -42)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "Byte", value: "-42")])
    }

    func test_short_serializesShortIntoQuery() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.shortHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        let input = ShortHTTPQueryInput(value: 1234)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "Short", value: "1234")])
    }

    func test_integer_serializesIntegerIntoQuery() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.integerHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        let input = IntegerHTTPQueryInput(value: 8675309)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "Integer", value: "8675309")])
    }

    func test_long_serializesLongIntoQuery() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.longHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        let input = LongHTTPQueryInput(value: 9876543210)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "Long", value: "9876543210")])
    }

    func test_float_serializesFloatIntoQuery() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.floatHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        let input = FloatHTTPQueryInput(value: 3.5)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "Float", value: "3.5")])
    }

    func test_float_serializesNonFiniteFloatUsingSmithyTokens() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.floatHTTPQueryOperation

        for (value, expected) in [(Float.nan, "NaN"), (.infinity, "Infinity"), (-.infinity, "-Infinity")] {
            let subject = HTTPQuerySerializer()
            let input = FloatHTTPQueryInput(value: value)
            try input.serializeMembers(operation.inputSchema, subject)
            XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "Float", value: expected)])
        }
    }

    func test_double_serializesDoubleIntoQuery() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.doubleHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        let input = DoubleHTTPQueryInput(value: 2.25)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "Double", value: "2.25")])
    }

    func test_double_serializesNonFiniteDoubleUsingSmithyTokens() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.doubleHTTPQueryOperation

        for (value, expected) in [(Double.nan, "NaN"), (.infinity, "Infinity"), (-.infinity, "-Infinity")] {
            let subject = HTTPQuerySerializer()
            let input = DoubleHTTPQueryInput(value: value)
            try input.serializeMembers(operation.inputSchema, subject)
            XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "Double", value: expected)])
        }
    }

    // MARK: - string HTTP query

    func test_string_serializesStringIntoQuery() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.stringHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        let input = StringHTTPQueryInput(value: "abcdef")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "String", value: "abcdef")])
    }

    func test_string_percentEncodesSpecialCharactersInValueIncludingSlash() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.stringHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        // Only RFC 3986 unreserved characters are left unescaped in query values.
        let input = StringHTTPQueryInput(value: "abc/*=")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "String", value: "abc%2F%2A%3D")])
    }

    func test_string_percentEncodesQueryParameterName() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.encodedNameHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        let input = EncodedNameHTTPQueryInput(value: "value")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "name%20with%20spaces", value: "value")])
    }

    // MARK: - timestamp HTTP query

    func test_timestamp_serializesTimestampAsDateTimeByDefault() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.timestampHTTPQueryOperation
        let dateTimeString = "2026-07-09T21:43:14.762Z"
        let moment = TimestampFormatter(format: .dateTime).date(from: dateTimeString)
        let subject = HTTPQuerySerializer()

        let input = TimestampHTTPQueryInput(moment: moment)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "Moment", value: "2026-07-09T21%3A43%3A14.762Z")])
    }

    func test_timestamp_serializesTimestampUsingTimestampFormatTrait() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.formattedTimestampHTTPQueryOperation
        let dateTimeString = "2026-07-09T21:43:14.762Z"
        let moment = TimestampFormatter(format: .dateTime).date(from: dateTimeString)
        let subject = HTTPQuerySerializer()

        let input = FormattedTimestampHTTPQueryInput(moment: moment)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(
            subject.queryItems,
            [URIQueryItem(name: "Moment", value: "Thu%2C%2009%20Jul%202026%2021%3A43%3A14.762%20GMT")]
        )
    }

    // MARK: - list HTTP query

    func test_list_serializesEachElementAsRepeatedQueryItem() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.stringListHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        // Per the spec, a list member serializes to multiple query items sharing the same name,
        // e.g. `Word=a&Word=b`, preserving element order.
        let input = StringListHTTPQueryInput(words: ["a", "b"])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [
            URIQueryItem(name: "Word", value: "a"),
            URIQueryItem(name: "Word", value: "b"),
        ])
    }

    func test_list_percentEncodesEachElement() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.stringListHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        let input = StringListHTTPQueryInput(words: ["a/b", "c d"])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [
            URIQueryItem(name: "Word", value: "a%2Fb"),
            URIQueryItem(name: "Word", value: "c%20d"),
        ])
    }

    func test_list_emptyListProducesNoQueryItems() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.stringListHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        let input = StringListHTTPQueryInput(words: [])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [])
    }

    // MARK: - sparse list HTTP query

    func test_sparseList_serializesNilElementsAsTheNullLiteral() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.sparseStringListHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        // A sparse list may contain nil elements; each is serialized as the literal string "null",
        // keeping its position relative to the present elements under the shared query name.
        let input = SparseStringListHTTPQueryInput(words: ["a", nil, "b"])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [
            URIQueryItem(name: "Word", value: "a"),
            URIQueryItem(name: "Word", value: "null"),
            URIQueryItem(name: "Word", value: "b"),
        ])
    }

    // MARK: - multiple & omitted members

    func test_multipleMembers_eachProduceItsOwnQueryItem() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.multipleHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        let input = MultipleHTTPQueryInput(count: 5, key: "abc")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(Set(subject.queryItems), Set([
            URIQueryItem(name: "Key", value: "abc"),
            URIQueryItem(name: "Count", value: "5"),
        ]))
    }

    func test_omittedOptionalMemberProducesNoQueryItem() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.multipleHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        let input = MultipleHTTPQueryInput(count: nil, key: "abc")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [URIQueryItem(name: "Key", value: "abc")])
    }

    func test_allMembersOmittedProducesNoQueryItems() throws {
        let operation = HTTPQueryTestSDK.HTTPQueryClient.multipleHTTPQueryOperation
        let subject = HTTPQuerySerializer()

        let input = MultipleHTTPQueryInput()
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.queryItems, [])
    }
}
