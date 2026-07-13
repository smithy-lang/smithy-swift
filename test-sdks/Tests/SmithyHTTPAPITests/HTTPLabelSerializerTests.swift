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
@testable import RestJSON1TestSDK

final class HTTPLabelSerializerTests: XCTestCase {

    // MARK: - boolean HTTP labels

    func test_boolean_serializesBooleanIntoURI() throws {
        let operation = RestJSON1TestSDK.RestJSON1Client.booleanHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = BooleanHTTPLabelInput(answer: true)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/boolean/true")
    }

    // MARK: - numeric HTTP labels

    func test_byte_serializesByteIntoURI() throws {
        let operation = RestJSON1TestSDK.RestJSON1Client.byteHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = ByteHTTPLabelInput(quantity: -42)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/byte/-42")
    }

    func test_short_serializesShortIntoURI() throws {
        let operation = RestJSON1TestSDK.RestJSON1Client.shortHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = ShortHTTPLabelInput(quantity: 1234)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/short/1234")
    }

    func test_number_serializesNumberIntoURI() throws {
        let operation = RestJSON1TestSDK.RestJSON1Client.integerHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = IntegerHTTPLabelInput(quantity: 8675309)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/integer/8675309")
    }

    func test_long_serializesLongIntoURI() throws {
        let operation = RestJSON1TestSDK.RestJSON1Client.longHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = LongHTTPLabelInput(quantity: 9876543210)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/long/9876543210")
    }

    func test_float_serializesFloatIntoURI() throws {
        let operation = RestJSON1TestSDK.RestJSON1Client.floatHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = FloatHTTPLabelInput(quantity: 3.5)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/float/3.5")
    }

    func test_float_serializesNonFiniteFloatUsingSmithyTokens() throws {
        let operation = RestJSON1TestSDK.RestJSON1Client.floatHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)

        for (value, expected) in [(Float.nan, "NaN"), (.infinity, "Infinity"), (-.infinity, "-Infinity")] {
            let subject = HTTPLabelSerializer(uri: uri)
            let input = FloatHTTPLabelInput(quantity: value)
            try input.serializeMembers(operation.inputSchema, subject)
            XCTAssertEqual(subject.uri, "/float/\(expected)")
        }
    }

    func test_double_serializesDoubleIntoURI() throws {
        let operation = RestJSON1TestSDK.RestJSON1Client.doubleHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = DoubleHTTPLabelInput(quantity: 2.25)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/double/2.25")
    }

    func test_double_serializesNonFiniteDoubleUsingSmithyTokens() throws {
        let operation = RestJSON1TestSDK.RestJSON1Client.doubleHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)

        for (value, expected) in [(Double.nan, "NaN"), (.infinity, "Infinity"), (-.infinity, "-Infinity")] {
            let subject = HTTPLabelSerializer(uri: uri)
            let input = DoubleHTTPLabelInput(quantity: value)
            try input.serializeMembers(operation.inputSchema, subject)
            XCTAssertEqual(subject.uri, "/double/\(expected)")
        }
    }

    // MARK: - string HTTP labels

    func test_string_serializesStringIntoURI() throws {
        let operation = RestJSON1TestSDK.RestJSON1Client.stringHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = StringHTTPLabelInput(word: "abcdef")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/string/abcdef")
    }

    func test_string_serializesStringIntoURIEscapingSpecialCharactersIncludingSlash() throws {
        let operation = RestJSON1TestSDK.RestJSON1Client.stringHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = StringHTTPLabelInput(word: "abc/*=")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/string/abc%2F%2A%3D")
    }

    func test_greedyString_serializesStringIntoURIEscapingSpecialCharactersIncludingSlash() throws {
        let operation = RestJSON1TestSDK.RestJSON1Client.greedyStringHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = GreedyStringHTTPLabelInput(word: "abc/*=")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/greedyString/abc/%2A%3D")
    }

    // MARK: - timestamp HTTP labels

    func test_timestamp_serializesTimestampIntoURIAsDateTimeByDefault() throws {
        let operation = RestJSON1TestSDK.RestJSON1Client.timestampHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let dateTimeString = "2026-07-09T21:43:14.762Z"
        let moment = TimestampFormatter(format: .dateTime).date(from: dateTimeString)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = TimestampHTTPLabelInput(moment: moment)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/timestamp/2026-07-09T21%3A43%3A14.762Z")
    }

    func test_timestamp_serializesTimestampIntoURIUsingTimestampFormatTrait() throws {
        let operation = RestJSON1TestSDK.RestJSON1Client.formattedTimestampHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let dateTimeString = "2026-07-09T21:43:14.762Z"
        let moment = TimestampFormatter(format: .dateTime).date(from: dateTimeString)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = FormattedTimestampHTTPLabelInput(moment: moment)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/formattedTimestamp/Thu%2C%2009%20Jul%202026%2021%3A43%3A14.762%20GMT")
    }
}
