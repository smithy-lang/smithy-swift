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

// Tests that `HTTPHeaderDeserializer` implements the behavior defined for the `httpHeader` trait:
// https://smithy.io/2.0/spec/http-bindings.html#httpheader-trait
final class HTTPHeaderDeserializerTests: XCTestCase {

    // MARK: - boolean HTTP header

    func test_boolean_deserializesTrue() throws {
        let output = try deserialize(BooleanHTTPHeaderOutput.self, ["X-Flag": "true"])

        XCTAssertEqual(output.flag, true)
    }

    func test_boolean_deserializesFalse() throws {
        let output = try deserialize(BooleanHTTPHeaderOutput.self, ["X-Flag": "false"])

        XCTAssertEqual(output.flag, false)
    }

    func test_boolean_throwsWhenHeaderIsNotABoolean() throws {
        XCTAssertThrowsError(try deserialize(BooleanHTTPHeaderOutput.self, ["X-Flag": "yes"]))
    }

    // MARK: - numeric HTTP header

    func test_byte_deserializesByteFromHeader() throws {
        let output = try deserialize(ByteHTTPHeaderOutput.self, ["X-Byte": "-42"])

        XCTAssertEqual(output.value, -42)
    }

    func test_byte_throwsWhenHeaderOverflowsByte() throws {
        XCTAssertThrowsError(try deserialize(ByteHTTPHeaderOutput.self, ["X-Byte": "128"]))
    }

    func test_short_deserializesShortFromHeader() throws {
        let output = try deserialize(ShortHTTPHeaderOutput.self, ["X-Short": "1234"])

        XCTAssertEqual(output.value, 1234)
    }

    func test_integer_deserializesIntegerFromHeader() throws {
        let output = try deserialize(IntegerHTTPHeaderOutput.self, ["X-Integer": "8675309"])

        XCTAssertEqual(output.value, 8675309)
    }

    func test_long_deserializesLongFromHeader() throws {
        let output = try deserialize(LongHTTPHeaderOutput.self, ["X-Long": "9876543210"])

        XCTAssertEqual(output.value, 9876543210)
    }

    func test_integer_throwsWhenHeaderIsNotANumber() throws {
        XCTAssertThrowsError(try deserialize(IntegerHTTPHeaderOutput.self, ["X-Integer": "12abc"]))
    }

    func test_float_deserializesFloatFromHeader() throws {
        let output = try deserialize(FloatHTTPHeaderOutput.self, ["X-Float": "3.5"])

        XCTAssertEqual(output.value, 3.5)
    }

    func test_float_deserializesNonFiniteFloatFromSmithyTokens() throws {
        XCTAssertEqual(try deserialize(FloatHTTPHeaderOutput.self, ["X-Float": "Infinity"]).value, .infinity)
        XCTAssertEqual(try deserialize(FloatHTTPHeaderOutput.self, ["X-Float": "-Infinity"]).value, -.infinity)
        // NaN never compares equal to itself, so it is checked for its own property instead.
        XCTAssertEqual(try deserialize(FloatHTTPHeaderOutput.self, ["X-Float": "NaN"]).value?.isNaN, true)
    }

    func test_double_deserializesDoubleFromHeader() throws {
        let output = try deserialize(DoubleHTTPHeaderOutput.self, ["X-Double": "2.25"])

        XCTAssertEqual(output.value, 2.25)
    }

    func test_double_deserializesNonFiniteDoubleFromSmithyTokens() throws {
        XCTAssertEqual(try deserialize(DoubleHTTPHeaderOutput.self, ["X-Double": "Infinity"]).value, .infinity)
        XCTAssertEqual(try deserialize(DoubleHTTPHeaderOutput.self, ["X-Double": "-Infinity"]).value, -.infinity)
        XCTAssertEqual(try deserialize(DoubleHTTPHeaderOutput.self, ["X-Double": "NaN"]).value?.isNaN, true)
    }

    func test_double_throwsWhenHeaderIsNotADouble() throws {
        XCTAssertThrowsError(try deserialize(DoubleHTTPHeaderOutput.self, ["X-Double": "two"]))
    }

    // MARK: - string HTTP header

    func test_string_deserializesStringFromHeader() throws {
        let output = try deserialize(StringHTTPHeaderOutput.self, ["X-String": "abcdef"])

        XCTAssertEqual(output.value, "abcdef")
    }

    func test_string_deserializesStringVerbatimWithoutUnquotingForScalarMember() throws {
        // A scalar string member is not a list element, so it is never unquoted or split; the
        // header value is taken as-is even when it holds characters significant to a list.
        let output = try deserialize(StringHTTPHeaderOutput.self, ["X-String": "\"a,b (c)\""])

        XCTAssertEqual(output.value, "\"a,b (c)\"")
    }

    // MARK: - media type HTTP header

    func test_mediaType_decodesBase64EncodedStringFromHeader() throws {
        // A string carrying the mediaType trait is always base64 encoded in a header.
        let output = try deserialize(MediaTypeHTTPHeaderOutput.self, ["X-Json": "eyJhIjoxfQ=="])

        XCTAssertEqual(output.value, #"{"a":1}"#)
    }

    func test_mediaType_decodesEmptyHeaderValueAsEmptyString() throws {
        let output = try deserialize(MediaTypeHTTPHeaderOutput.self, ["X-Json": ""])

        XCTAssertEqual(output.value, "")
    }

    func test_mediaType_throwsWhenHeaderIsNotValidBase64() throws {
        XCTAssertThrowsError(try deserialize(MediaTypeHTTPHeaderOutput.self, ["X-Json": #"{"a":1}"#]))
    }

    func test_mediaType_roundTripsValueWrittenByTheSerializer() throws {
        let operation = HTTPHeaderClient.mediaTypeHTTPHeaderOperation
        let value = #"{"a":1}"#
        let serializer = HTTPHeaderSerializer()
        try MediaTypeHTTPHeaderInput(value: value).serializeMembers(operation.inputSchema, serializer)

        let output = try deserialize(MediaTypeHTTPHeaderOutput.self, serializer.headers)

        XCTAssertEqual(output.value, value)
    }

    func test_mediaTypeList_decodesEachElementFromBase64() throws {
        // The trait is resolved from each element of the list, so every element is decoded.
        let output = try deserialize(
            MediaTypeListHTTPHeaderOutput.self,
            ["X-Json": "eyJhIjoxfQ==,eyJiIjoyfQ=="]
        )

        XCTAssertEqual(output.values, [#"{"a":1}"#, #"{"b":2}"#])
    }

    func test_mediaTypeList_roundTripsValuesWrittenByTheSerializer() throws {
        let operation = HTTPHeaderClient.mediaTypeListHTTPHeaderOperation
        let values = [#"{"a":1}"#, #"{"b":2}"#]
        let serializer = HTTPHeaderSerializer()
        try MediaTypeListHTTPHeaderInput(values: values).serializeMembers(operation.inputSchema, serializer)

        let output = try deserialize(MediaTypeListHTTPHeaderOutput.self, serializer.headers)

        XCTAssertEqual(output.values, values)
    }

    // MARK: - timestamp HTTP header

    func test_timestamp_deserializesTimestampAsHTTPDateByDefault() throws {
        // Unlike other bindings, headers default to the http-date (IMF-fixdate) format.
        let output = try deserialize(
            TimestampHTTPHeaderOutput.self,
            ["X-Moment": "Thu, 09 Jul 2026 21:43:14.762 GMT"]
        )

        XCTAssertEqual(output.moment, date("2026-07-09T21:43:14.762Z"))
    }

    func test_timestamp_deserializesTimestampUsingTimestampFormatTrait() throws {
        // The timestampFormat trait overrides the default with date-time.
        let output = try deserialize(
            FormattedTimestampHTTPHeaderOutput.self,
            ["X-Moment": "2026-07-09T21:43:14.762Z"]
        )

        XCTAssertEqual(output.moment, date("2026-07-09T21:43:14.762Z"))
    }

    func test_timestamp_throwsWhenHeaderIsNotInTheExpectedFormat() throws {
        // A date-time value does not parse as the http-date format that this member defaults to.
        XCTAssertThrowsError(
            try deserialize(TimestampHTTPHeaderOutput.self, ["X-Moment": "2026-07-09T21:43:14.762Z"])
        )
    }

    // MARK: - list HTTP header

    func test_list_deserializesCommaDelimitedHeaderValueIntoElements() throws {
        let output = try deserialize(StringListHTTPHeaderOutput.self, ["X-Word": "a,b,c"])

        XCTAssertEqual(output.words, ["a", "b", "c"])
    }

    func test_list_deserializesRepeatedHeaderIntoElements() throws {
        // A list may also arrive as the same header repeated, one element per line.
        let output = try deserialize(StringListHTTPHeaderOutput.self, ["X-Word": ["a", "b"]])

        XCTAssertEqual(output.words, ["a", "b"])
    }

    func test_list_deserializesMixOfRepeatedAndCommaDelimitedHeaderValues() throws {
        let output = try deserialize(StringListHTTPHeaderOutput.self, ["X-Word": ["a,b", "c"]])

        XCTAssertEqual(output.words, ["a", "b", "c"])
    }

    func test_list_trimsWhitespaceAroundUnquotedElements() throws {
        let output = try deserialize(StringListHTTPHeaderOutput.self, ["X-Word": " a ,  b  , c "])

        XCTAssertEqual(output.words, ["a", "b", "c"])
    }

    func test_list_unquotesQuotedElementsAndPreservesTheirContents() throws {
        // Quoting is what lets an element hold a comma, a quote, or surrounding whitespace; the
        // quotes and their escapes are removed, and everything they enclose is kept verbatim.
        let output = try deserialize(
            StringListHTTPHeaderOutput.self,
            ["X-Word": "\"a,b\",plain,\" c \",\"d\\\"e\""]
        )

        XCTAssertEqual(output.words, ["a,b", "plain", " c ", "d\"e"])
    }

    func test_list_roundTripsValuesWrittenByTheSerializer() throws {
        let operation = HTTPHeaderClient.stringListHTTPHeaderOperation
        let words = ["a,b", "plain", " c ", "d\"e", "f(g)"]
        let serializer = HTTPHeaderSerializer()
        try StringListHTTPHeaderInput(words: words).serializeMembers(operation.inputSchema, serializer)

        let output = try deserialize(StringListHTTPHeaderOutput.self, serializer.headers)

        XCTAssertEqual(output.words, words)
    }

    func test_list_deserializesEmptyHeaderValueAsEmptyList() throws {
        // The serializer writes an empty list as a header present with an empty value.
        let output = try deserialize(StringListHTTPHeaderOutput.self, ["X-Word": ""])

        XCTAssertEqual(output.words, [])
    }

    func test_list_deserializesEachNumericElement() throws {
        let output = try deserialize(IntegerListHTTPHeaderOutput.self, ["X-Number": "1,-2,3"])

        XCTAssertEqual(output.numbers, [1, -2, 3])
    }

    func test_list_throwsWhenAQuotedElementIsUnclosed() throws {
        XCTAssertThrowsError(try deserialize(StringListHTTPHeaderOutput.self, ["X-Word": "\"a,b"]))
    }

    func test_list_throwsWhenTextFollowsAQuotedElement() throws {
        XCTAssertThrowsError(try deserialize(StringListHTTPHeaderOutput.self, ["X-Word": "\"a\"b,c"]))
    }

    // MARK: - sparse list HTTP header

    func test_sparseList_deserializesTheNullLiteralAsANilElement() throws {
        // A sparse list's nil elements are serialized as the literal string "null".
        let output = try deserialize(SparseStringListHTTPHeaderOutput.self, ["X-Word": "a,null,b"])

        XCTAssertEqual(output.words, ["a", nil, "b"])
    }

    func test_sparseList_deserializesTheQuotedNullLiteralAsAStringElement() throws {
        // Quoting distinguishes the string "null" from a nil element.
        let output = try deserialize(SparseStringListHTTPHeaderOutput.self, ["X-Word": "a,\"null\",b"])

        XCTAssertEqual(output.words, ["a", "null", "b"])
    }

    func test_nonSparseList_deserializesTheNullLiteralAsAStringElement() throws {
        // A non-sparse list cannot hold a nil element, so "null" is just another string.
        let output = try deserialize(StringListHTTPHeaderOutput.self, ["X-Word": "a,null,b"])

        XCTAssertEqual(output.words, ["a", "null", "b"])
    }

    // MARK: - timestamp list HTTP header

    func test_timestampList_splitsHTTPDateListOnEverySecondComma() throws {
        // The http-date format contains a comma of its own, so only every second comma delimits
        // one timestamp from the next.
        let output = try deserialize(
            TimestampListHTTPHeaderOutput.self,
            ["X-Moment": "Mon, 16 Dec 2019 23:48:18 GMT, Tue, 17 Dec 2019 23:48:18 GMT"]
        )

        XCTAssertEqual(output.moments, [date("2019-12-16T23:48:18Z"), date("2019-12-17T23:48:18Z")])
    }

    func test_timestampList_deserializesSingleHTTPDateWithItsOwnComma() throws {
        let output = try deserialize(
            TimestampListHTTPHeaderOutput.self,
            ["X-Moment": "Mon, 16 Dec 2019 23:48:18 GMT"]
        )

        XCTAssertEqual(output.moments, [date("2019-12-16T23:48:18Z")])
    }

    func test_timestampList_deserializesRepeatedHTTPDateHeader() throws {
        let output = try deserialize(
            TimestampListHTTPHeaderOutput.self,
            ["X-Moment": ["Mon, 16 Dec 2019 23:48:18 GMT", "Tue, 17 Dec 2019 23:48:18 GMT"]]
        )

        XCTAssertEqual(output.moments, [date("2019-12-16T23:48:18Z"), date("2019-12-17T23:48:18Z")])
    }

    func test_timestampList_throwsWhenHTTPDateListHasAnEvenNumberOfCommas() throws {
        // Every http-date holds one comma, so a well-formed list always has an odd comma count.
        XCTAssertThrowsError(
            try deserialize(
                TimestampListHTTPHeaderOutput.self,
                ["X-Moment": "Mon, 16 Dec 2019 23:48:18 GMT, , Tue, 17 Dec 2019 23:48:18 GMT"]
            )
        )
    }

    func test_timestampList_splitsFormattedTimestampListOnEveryComma() throws {
        // The date-time format holds no comma, so its elements are split like any other list.
        let output = try deserialize(
            FormattedTimestampListHTTPHeaderOutput.self,
            ["X-Moment": "2019-12-16T23:48:18Z,2019-12-17T23:48:18Z"]
        )

        XCTAssertEqual(output.moments, [date("2019-12-16T23:48:18Z"), date("2019-12-17T23:48:18Z")])
    }

    func test_timestampList_roundTripsValuesWrittenByTheSerializer() throws {
        let operation = HTTPHeaderClient.timestampListHTTPHeaderOperation
        let moments = [date("2019-12-16T23:48:18Z"), date("2019-12-17T23:48:18Z")]
        let serializer = HTTPHeaderSerializer()
        try TimestampListHTTPHeaderInput(moments: moments).serializeMembers(operation.inputSchema, serializer)

        let output = try deserialize(TimestampListHTTPHeaderOutput.self, serializer.headers)

        XCTAssertEqual(output.moments, moments)
    }

    // MARK: - multiple, repeated, absent & unbound members

    func test_multipleMembers_eachDeserializesFromItsOwnHeader() throws {
        let output = try deserialize(MultipleHTTPHeaderOutput.self, ["X-Key": "abc", "X-Count": "5"])

        XCTAssertEqual(output.key, "abc")
        XCTAssertEqual(output.count, 5)
    }

    func test_absentHeaderLeavesItsMemberUnset() throws {
        let output = try deserialize(MultipleHTTPHeaderOutput.self, ["X-Key": "abc"])

        XCTAssertEqual(output.key, "abc")
        XCTAssertNil(output.count)
    }

    func test_noHeadersLeavesAllMembersUnset() throws {
        let output = try deserialize(MultipleHTTPHeaderOutput.self, Headers())

        XCTAssertNil(output.key)
        XCTAssertNil(output.count)
    }

    func test_headerNameIsMatchedCaseInsensitively() throws {
        // HTTP header names are case-insensitive, so a differently cased name still binds.
        let output = try deserialize(MultipleHTTPHeaderOutput.self, ["x-key": "abc", "X-COUNT": "5"])

        XCTAssertEqual(output.key, "abc")
        XCTAssertEqual(output.count, 5)
    }

    func test_unboundMemberIsLeftUnsetForAnotherBindingToFill() throws {
        // Only members carrying the httpHeader trait are deserialized; a member bound elsewhere
        // (or to the payload) is left untouched.
        let output = try deserialize(MultipleHTTPHeaderOutput.self, ["X-Key": "abc", "unbound": "xyz"])

        XCTAssertEqual(output.key, "abc")
        XCTAssertNil(output.unbound)
    }

    func test_scalarMemberBoundToARepeatedHeaderReadsTheJoinedValue() throws {
        // A scalar member should not receive a repeated header, but if one arrives its values are
        // read as their comma-delimited equivalent rather than silently dropping any of them.
        let output = try deserialize(StringHTTPHeaderOutput.self, ["X-String": ["a", "b"]])

        XCTAssertEqual(output.value, "a,b")
    }

    // MARK: - error response

    func test_error_deserializesHeadersIntoErrorProperties() throws {
        // An error structure binds headers to its members the same way an output structure does,
        // except that the members live under `properties`.
        let error = try deserialize(
            HTTPHeaderError.self,
            ["X-Key": "abc", "X-Count": "5", "X-Word": "a,b"]
        )

        XCTAssertEqual(error.properties.key, "abc")
        XCTAssertEqual(error.properties.count, 5)
        XCTAssertEqual(error.properties.words, ["a", "b"])
    }

    func test_error_absentHeaderLeavesItsPropertyUnset() throws {
        let error = try deserialize(HTTPHeaderError.self, ["X-Key": "abc"])

        XCTAssertEqual(error.properties.key, "abc")
        XCTAssertNil(error.properties.count)
        XCTAssertNil(error.properties.words)
    }

    // MARK: - unsupported bindings

    func test_readMap_throwsBecauseAMapCannotBeBoundToAHeader() throws {
        let subject = HTTPHeaderDeserializer(headers: Headers())
        let schema = Schema(id: ShapeID("smithy.swift.tests", "Map"), type: .map)

        XCTAssertThrowsError(try subject.readMap(schema) { _ in "" })
    }

    func test_readBlob_throwsBecauseABlobCannotBeBoundToAHeader() throws {
        let subject = HTTPHeaderDeserializer(headers: Headers())
        let schema = Schema(id: ShapeID("smithy.swift.tests", "Blob"), type: .blob)

        XCTAssertThrowsError(try subject.readBlob(schema))
    }

    func test_readDocument_throwsBecauseADocumentCannotBeBoundToAHeader() throws {
        let subject = HTTPHeaderDeserializer(headers: Headers())
        let schema = Schema(id: ShapeID("smithy.swift.tests", "Document"), type: .document)

        XCTAssertThrowsError(try subject.readDocument(schema))
    }

    // MARK: - Private methods

    private func deserialize<T: DeserializableStruct>(_ type: T.Type, _ headers: [String: String]) throws -> T {
        try deserialize(type, Headers(headers))
    }

    private func deserialize<T: DeserializableStruct>(_ type: T.Type, _ headers: [String: [String]]) throws -> T {
        try deserialize(type, Headers(headers))
    }

    private func deserialize<T: DeserializableStruct>(_ type: T.Type, _ headers: Headers) throws -> T {
        try T.deserialize(HTTPHeaderDeserializer(headers: headers))
    }

    private func date(_ dateTimeString: String) -> Date {
        TimestampFormatter(format: .dateTime).date(from: dateTimeString)!
    }
}
