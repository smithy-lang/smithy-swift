//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SchemaBasedSerde)
import SmithySerialization
@_spi(SchemaBasedSerde)
import enum Smithy.Prelude
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import class Smithy.SensitiveTrait
import struct StringSerializerTestSDK.GetWidgetOutput
import enum StringSerializerTestSDK.StringSerializerClientTypes

final class StringSerializerTests: XCTestCase {
    typealias TestStruct = StringSerializerClientTypes.SensitiveType

    func test_writesASimpleString() throws {
        let string = "xyz"
        let schema = Smithy.Prelude.stringSchema

        let subject = StringSerializer()
        try subject.writeString(schema, string)

        XCTAssertEqual(subject.string, "\"\(string)\"")
    }

    func test_writesASimpleInt() throws {
        let int = 8675309
        let schema = Smithy.Prelude.integerSchema

        let subject = StringSerializer()
        try subject.writeInteger(schema, int)

        XCTAssertEqual(subject.string, "\(int)")
    }

    func test_writesATimestamp() throws {
        let dateString = "2026-01-21T20:23:32Z"
        let df = ISO8601DateFormatter()
        let date = try XCTUnwrap(df.date(from: dateString))
        let schema = Smithy.Prelude.timestampSchema

        let subject = StringSerializer()
        try subject.writeTimestamp(schema, date)

        XCTAssertEqual(subject.string, dateString)
    }

    func test_writesAnEmptyList() throws {
        let subject = TestStruct(publicList: [])

        XCTAssertEqual(subject.debugDescription, "SensitiveType(publicList: [])")
    }

    func test_writesAStringList() throws {
        let subject = TestStruct(publicList: ["abc", "def", "ghi"])

        XCTAssertEqual(subject.debugDescription, "SensitiveType(publicList: [\"abc\", \"def\", \"ghi\"])")
    }

    func test_writesAnEmptyMap() throws {
        let subject = TestStruct(publicMap: [:])

        XCTAssertEqual(subject.debugDescription, "SensitiveType(publicMap: [:])")
    }

    func test_writesAStringMap() throws {
        let subject = TestStruct(publicMap: ["x": "abc", "y": "def"])

        XCTAssert(
            subject.debugDescription == "SensitiveType(publicMap: [\"x\": \"abc\", \"y\": \"def\"])" ||
            subject.debugDescription == "SensitiveType(publicMap: [\"y\": \"def\", \"x\": \"abc\"])"
        )
    }

    func test_redactsStringProperty() throws {
        let subject = TestStruct(privateString: "def", publicString: "abc")

        XCTAssertEqual(subject.debugDescription, "SensitiveType(privateString: [CONTENT_REDACTED], publicString: \"abc\")")
    }

    func test_redactsAPrivateList() throws {
        let subject = TestStruct(privateList: ["abc", "def", "ghi"])

        XCTAssertEqual(subject.debugDescription, "SensitiveType(privateList: [[CONTENT_REDACTED], [CONTENT_REDACTED], [CONTENT_REDACTED]])")
    }

    func test_redactsAPrivateMap() throws {
        let subject = TestStruct(privateMap: ["x": "abc", "y": "def"])

        XCTAssert(
            subject.debugDescription == "SensitiveType(privateMap: [\"x\": [CONTENT_REDACTED], \"y\": [CONTENT_REDACTED]])" ||
            subject.debugDescription == "SensitiveType(privateMap: [\"y\": [CONTENT_REDACTED], \"x\": [CONTENT_REDACTED]])",
            "actual: \(subject.debugDescription)"
        )
    }

    func test_outputFieldsAreRedacted() throws {
        let sensitiveString = "abcxyz"
        let subject = GetWidgetOutput(privateString: sensitiveString)
        XCTAssertFalse(String(reflecting: subject).contains(sensitiveString))
    }
}

