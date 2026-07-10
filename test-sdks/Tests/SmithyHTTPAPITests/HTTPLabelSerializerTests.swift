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
        let operation = RestJSON1TestSDK.RestJSON1ServiceClient.booleanHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = BooleanHTTPLabelInput(answer: true)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/boolean/true")
    }

    // MARK: - numeric HTTP labels

    func test_number_serializesNumberIntoURI() throws {
        let operation = RestJSON1TestSDK.RestJSON1ServiceClient.integerHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = IntegerHTTPLabelInput(quantity: 8675309)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/integer/8675309")
    }

    // MARK: - string HTTP labels

    func test_string_serializesStringIntoURI() throws {
        let operation = RestJSON1TestSDK.RestJSON1ServiceClient.stringHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = StringHTTPLabelInput(word: "abcdef")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/string/abcdef")
    }

    func test_string_serializesStringIntoURIEscapingSpecialCharactersIncludingSlash() throws {
        let operation = RestJSON1TestSDK.RestJSON1ServiceClient.stringHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = StringHTTPLabelInput(word: "abc/*=")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/string/abc%2F%2A%3D")
    }

    func test_greedyString_serializesStringIntoURIEscapingSpecialCharactersIncludingSlash() throws {
        let operation = RestJSON1TestSDK.RestJSON1ServiceClient.greedyStringHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = GreedyStringHTTPLabelInput(word: "abc/*=")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/greedyString/abc/%2A%3D")
    }

    // MARK: - timestamp HTTP labels

    func test_timestamp_serializesTimestampIntoURIAsDateTimeByDefault() throws {
        let operation = RestJSON1TestSDK.RestJSON1ServiceClient.timestampHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let dateTimeString = "2026-07-09T21:43:14.762Z"
        let moment = TimestampFormatter(format: .dateTime).date(from: dateTimeString)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = TimestampHTTPLabelInput(moment: moment)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/timestamp/2026-07-09T21%3A43%3A14.762Z")
    }

    func test_timestamp_serializesTimestampIntoURIUsingTimestampFormatTrait() throws {
        let operation = RestJSON1TestSDK.RestJSON1ServiceClient.formattedTimestampHTTPLabelOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let dateTimeString = "2026-07-09T21:43:14.762Z"
        let moment = TimestampFormatter(format: .dateTime).date(from: dateTimeString)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = FormattedTimestampHTTPLabelInput(moment: moment)
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/formattedTimestamp/Thu%2C%2009%20Jul%202026%2021%3A43%3A14.762%20GMT")
    }
}
