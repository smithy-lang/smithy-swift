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
@testable import HTTPHeaderTestSDK

// Tests that `HTTPHeaderSerializer` implements the behavior defined for the `httpHeader` trait:
// https://smithy.io/2.0/spec/http-bindings.html#httpheader-trait
final class HTTPHeaderSerializerTests: XCTestCase {

    // MARK: - boolean HTTP header

    func test_boolean_serializesTrue() throws {
        let operation = HTTPHeaderClient.booleanHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        let input = BooleanHTTPHeaderInput(flag: true)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Flag"), ["true"])
    }

    func test_boolean_serializesFalse() throws {
        let operation = HTTPHeaderClient.booleanHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        let input = BooleanHTTPHeaderInput(flag: false)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Flag"), ["false"])
    }

    // MARK: - numeric HTTP header

    func test_byte_serializesByteIntoHeader() throws {
        let operation = HTTPHeaderClient.byteHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        let input = ByteHTTPHeaderInput(value: -42)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Byte"), ["-42"])
    }

    func test_short_serializesShortIntoHeader() throws {
        let operation = HTTPHeaderClient.shortHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        let input = ShortHTTPHeaderInput(value: 1234)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Short"), ["1234"])
    }

    func test_integer_serializesIntegerIntoHeader() throws {
        let operation = HTTPHeaderClient.integerHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        let input = IntegerHTTPHeaderInput(value: 8675309)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Integer"), ["8675309"])
    }

    func test_long_serializesLongIntoHeader() throws {
        let operation = HTTPHeaderClient.longHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        let input = LongHTTPHeaderInput(value: 9876543210)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Long"), ["9876543210"])
    }

    func test_float_serializesFloatIntoHeader() throws {
        let operation = HTTPHeaderClient.floatHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        let input = FloatHTTPHeaderInput(value: 3.5)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Float"), ["3.5"])
    }

    func test_float_serializesNonFiniteFloatUsingSmithyTokens() throws {
        let operation = HTTPHeaderClient.floatHTTPHeaderOperation

        for (value, expected) in [(Float.nan, "NaN"), (.infinity, "Infinity"), (-.infinity, "-Infinity")] {
            let subject = HTTPHeaderSerializer()
            let input = FloatHTTPHeaderInput(value: value)
            try input.serializeMembers(operation.inputSchema, subject)
            XCTAssertEqual(subject.headers.values(for: "X-Float"), [expected])
        }
    }

    func test_double_serializesDoubleIntoHeader() throws {
        let operation = HTTPHeaderClient.doubleHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        let input = DoubleHTTPHeaderInput(value: 2.25)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Double"), ["2.25"])
    }

    func test_double_serializesNonFiniteDoubleUsingSmithyTokens() throws {
        let operation = HTTPHeaderClient.doubleHTTPHeaderOperation

        for (value, expected) in [(Double.nan, "NaN"), (.infinity, "Infinity"), (-.infinity, "-Infinity")] {
            let subject = HTTPHeaderSerializer()
            let input = DoubleHTTPHeaderInput(value: value)
            try input.serializeMembers(operation.inputSchema, subject)
            XCTAssertEqual(subject.headers.values(for: "X-Double"), [expected])
        }
    }

    // MARK: - string HTTP header

    func test_string_serializesStringIntoHeader() throws {
        let operation = HTTPHeaderClient.stringHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        let input = StringHTTPHeaderInput(value: "abcdef")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-String"), ["abcdef"])
    }

    func test_string_serializesStringVerbatimWithoutQuotingForScalarMember() throws {
        let operation = HTTPHeaderClient.stringHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        // A scalar string member is not a list element, so it is never quoted even if it
        // contains characters that would require quoting inside a list value.
        let input = StringHTTPHeaderInput(value: "a,b (c)")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-String"), ["a,b (c)"])
    }

    // MARK: - timestamp HTTP header

    func test_timestamp_serializesTimestampAsHTTPDateByDefault() throws {
        let operation = HTTPHeaderClient.timestampHTTPHeaderOperation
        let dateTimeString = "2026-07-09T21:43:14.762Z"
        let moment = TimestampFormatter(format: .dateTime).date(from: dateTimeString)
        let subject = HTTPHeaderSerializer()

        let input = TimestampHTTPHeaderInput(moment: moment)
        try input.serializeMembers(operation.inputSchema, subject)

        // Unlike other bindings, headers default to the http-date (IMF-fixdate) format.
        XCTAssertEqual(subject.headers.values(for: "X-Moment"), ["Thu, 09 Jul 2026 21:43:14.762 GMT"])
    }

    func test_timestamp_serializesTimestampUsingTimestampFormatTrait() throws {
        let operation = HTTPHeaderClient.formattedTimestampHTTPHeaderOperation
        let dateTimeString = "2026-07-09T21:43:14.762Z"
        let moment = TimestampFormatter(format: .dateTime).date(from: dateTimeString)
        let subject = HTTPHeaderSerializer()

        let input = FormattedTimestampHTTPHeaderInput(moment: moment)
        try input.serializeMembers(operation.inputSchema, subject)

        // The timestampFormat trait overrides the default with date-time.
        XCTAssertEqual(subject.headers.values(for: "X-Moment"), ["2026-07-09T21:43:14.762Z"])
    }

    // MARK: - list HTTP header

    func test_list_serializesEachElementAsRepeatedHeaderValue() throws {
        let operation = HTTPHeaderClient.stringListHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        // Per the spec, a list member serializes to a header carrying every element, preserving
        // element order.
        let input = StringListHTTPHeaderInput(words: ["a", "b"])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Word"), ["a", "b"])
    }

    func test_list_quotesElementsThatContainDelimiterCharacters() throws {
        let operation = HTTPHeaderClient.stringListHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        // Elements containing a comma, quote, parens, or surrounding whitespace are quoted (and
        // any embedded backslash or quote escaped) so they survive the compact list encoding.
        let input = StringListHTTPHeaderInput(words: ["a,b", "plain", " c ", "d\"e"])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Word"), ["\"a,b\"", "plain", "\" c \"", "\"d\\\"e\""])
    }

    func test_list_emptyListProducesHeaderWithEmptyValue() throws {
        let operation = HTTPHeaderClient.stringListHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        let input = StringListHTTPHeaderInput(words: [])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Word"), [""])
    }

    func test_list_serializesEachNumericElementAsRepeatedHeaderValue() throws {
        let operation = HTTPHeaderClient.integerListHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        // Lists of scalars other than string reach the scalar writers through the shared header
        // name; each element is rendered with its scalar formatting under the repeated name.
        let input = IntegerListHTTPHeaderInput(numbers: [1, -2, 3])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Number"), ["1", "-2", "3"])
    }

    // MARK: - sparse list HTTP header

    func test_sparseList_serializesNilElementsAsTheNullLiteral() throws {
        let operation = HTTPHeaderClient.sparseStringListHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        // A sparse list may contain nil elements; each is serialized as the literal string "null",
        // keeping its position relative to the present elements under the shared header name.
        let input = SparseStringListHTTPHeaderInput(words: ["a", nil, "b"])
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Word"), ["a", "null", "b"])
    }

    // MARK: - multiple & omitted members

    func test_multipleMembers_eachProduceItsOwnHeader() throws {
        let operation = HTTPHeaderClient.multipleHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        let input = MultipleHTTPHeaderInput(count: 5, key: "abc")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Key"), ["abc"])
        XCTAssertEqual(subject.headers.values(for: "X-Count"), ["5"])
    }

    func test_omittedOptionalMemberProducesNoHeader() throws {
        let operation = HTTPHeaderClient.multipleHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        let input = MultipleHTTPHeaderInput(count: nil, key: "abc")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Key"), ["abc"])
        XCTAssertNil(subject.headers.values(for: "X-Count"))
    }

    func test_allMembersOmittedProducesNoHeaders() throws {
        let operation = HTTPHeaderClient.multipleHTTPHeaderOperation
        let subject = HTTPHeaderSerializer()

        let input = MultipleHTTPHeaderInput()
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertTrue(subject.headers.isEmpty)
    }
}
