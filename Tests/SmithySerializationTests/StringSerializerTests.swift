//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SmithySerialization
import enum Smithy.Prelude
import struct Smithy.Schema
import struct Smithy.SensitiveTrait
import enum RPCv2CBORTestSDK.RPCv2CBORServiceClientTypes

final class StringSerializerTests: XCTestCase {
    typealias SensitiveType = RPCv2CBORServiceClientTypes.SensitiveType

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
        let subject = SensitiveType(publicList: [])

        XCTAssertEqual(subject.debugDescription, "SensitiveType(publicList: [])")
    }

    func test_writesAStringList() throws {
        let subject = SensitiveType(publicList: ["abc", "def", "ghi"])

        XCTAssertEqual(subject.debugDescription, "SensitiveType(publicList: [\"abc\", \"def\", \"ghi\"])")
    }

    func test_writesAnEmptyMap() throws {
        let subject = SensitiveType(publicMap: [:])

        XCTAssertEqual(subject.debugDescription, "SensitiveType(publicMap: [:])")
    }

    func test_writesAStringMap() throws {
        let subject = SensitiveType(publicMap: ["x": "abc", "y": "def"])

        XCTAssert(
            subject.debugDescription == "SensitiveType(publicMap: [\"x\": \"abc\", \"y\": \"def\"])" ||
            subject.debugDescription == "SensitiveType(publicMap: [\"y\": \"def\", \"x\": \"abc\"])"
        )
    }

    func test_redactsStringProperty() throws {
        let subject = SensitiveType(privateString: "def", publicString: "abc")

        XCTAssertEqual(subject.debugDescription, "SensitiveType(privateString: [REDACTED], publicString: \"abc\")")
    }

    func test_redactsAPrivateList() throws {
        let subject = SensitiveType(privateList: ["abc", "def", "ghi"])

        XCTAssertEqual(subject.debugDescription, "SensitiveType(privateList: [[REDACTED], [REDACTED], [REDACTED]])")
    }

    func test_redactsAPrivateMap() throws {
        let subject = SensitiveType(privateMap: ["x": "abc", "y": "def"])

        XCTAssert(
            subject.debugDescription == "SensitiveType(privateMap: [\"x\": [REDACTED], \"y\": [REDACTED]])" ||
            subject.debugDescription == "SensitiveType(privateMap: [\"y\": [REDACTED], \"x\": [REDACTED]])",
            "actual: \(subject.debugDescription)"
        )
    }
}
