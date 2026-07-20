//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SchemaBasedSerde)
@_spi(SmithyDocumentImpl)
import Smithy
@_spi(SchemaBasedSerde)
import SmithyJSON
@_spi(SchemaBasedSerde)
import SmithySerialization
@_spi(SmithyTimestamps)
import SmithyTimestamps
@_spi(SchemaBasedSerde) import AWSJSONTestSDK

final class SerializerTests: XCTestCase {

    // MARK: - strings

    func test_writeString_writesEmptyString() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(string: "")
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"string":""}"#)
    }

    func test_writeString_escapesTheMustEscapeCharacters() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        // original string contains all characters which must be escaped in JSON strings:
        // backspace, form feed, carriage return, tab, line feed, double quote, backslash
        // (escaped forward slash, required for embedding JSON in HTML, is not included)
        let original = "\(Character(Unicode.Scalar(8)!))\(Character(Unicode.Scalar(12)!))\r\t\n\"\\"
        let input = SerdeOperationInput(string: original)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"string":"\b\f\r\t\n\"\\"}"#)
    }

    func test_writeString_escapesCRLFSequenceWithoutCollapsing() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        // "\r\n" is a single Swift grapheme cluster; iterating Characters would collapse
        // it to a lone line feed and drop the carriage return, so verify both survive.
        let input = SerdeOperationInput(string: "line1\r\nline2")
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"string":"line1\r\nline2"}"#)
    }

    func test_writeString_writesUpperUnicodeCharacters() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(string: "🗑️ + 🐼 = 🦝")
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"string":"🗑️ + 🐼 = 🦝"}"#)
    }

    func test_writeString_escapesNonSpecialControlCharacters() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        // ASCII 8, 9, 10, 12, 13 are the "special" characters \b\f\r\t\n so exclude them here
        let nonspecialEscapedCharacters: [UInt8] = (0..<32).filter { ![8, 9, 10, 12, 13].contains($0) }
        let input = SerdeOperationInput(
            string: String(nonspecialEscapedCharacters.map { Character(UnicodeScalar($0)) })
        )
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        let expected = #"{"string":"\u0000\u0001\u0002\u0003\u0004\u0005\u0006\u0007\u000b\u000e\u000f"# +
            #"\u0010\u0011\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u001a\u001b\u001c\u001d\u001e\u001f"}"#
        XCTAssertEqual(json, expected)
    }

    // MARK: - blobs

    func test_writeBlob_writesAnEmptyDataBlobAsEmptyString() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let data = Data()
        let input = SerdeOperationInput(blob: data)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"blob":""}"#)
    }

    func test_writeBlob_writesADataBlobAsBase64String() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let data = Data("blobby blob blob".utf8)
        let input = SerdeOperationInput(blob: data)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"blob":"YmxvYmJ5IGJsb2IgYmxvYg=="}"#)
    }

    // MARK: - lists

    func test_writeList_writesAnEmptyList() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(list: [])
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"list":[]}"#)
    }

    func test_writeList_writesAOneElementList() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(list: [123])
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"list":[123]}"#)
    }

    func test_writeList_writesAMultiElementList() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(list: [123, 456, 789])
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"list":[123,456,789]}"#)
    }

    func test_writeList_writesNestedLists() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(nestedList: [["inner", "list"], ["another", "inner", "list"]])
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"nestedList":[["inner","list"],["another","inner","list"]]}"#)
    }

    // MARK: - boolean

    func test_writeBoolean_writesFalse() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(boolean: false)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"boolean":false}"#)
    }

    func test_writeBoolean_writesTrue() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(boolean: true)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"boolean":true}"#)
    }

    // MARK: - floating point

    func test_writeDouble_writesZero() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(double: 0.0)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"double":0.0}"#)
    }

    func test_writeDouble_writesPositiveNumber() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(double: 123.0)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"double":123.0}"#)
    }

    func test_writeDouble_writesNegativeNumber() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(double: -123.0)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"double":-123.0}"#)
    }

    func test_writeDouble_writesNaNAsString() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(double: .nan)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"double":"NaN"}"#)
    }

    func test_writeDouble_writesPositiveInfinityAsString() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(double: .infinity)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"double":"Infinity"}"#)
    }

    func test_writeDouble_writesNegativeInfinityAsString() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(double: -.infinity)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"double":"-Infinity"}"#)
    }

    // MARK: - timestamps

    func test_writeTimestamp_writesTimestampAsHttpDate() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let httpDate = "Thu, 09 Jul 2026 17:24:18.769 GMT"
        let date = TimestampFormatter(format: .httpDate).date(from: httpDate)
        let input = SerdeOperationInput(httpDateTimestamp: date)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, "{\"httpDateTimestamp\":\"\(httpDate)\"}")
    }

    func test_writeTimestamp_writesTimestampAsDateTime() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let dateTime = "2026-07-09T17:28:41.990Z"
        let date = TimestampFormatter(format: .dateTime).date(from: dateTime)
        let input = SerdeOperationInput(dateTimeTimestamp: date)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, "{\"dateTimeTimestamp\":\"\(dateTime)\"}")
    }

    func test_writeTimestamp_writesTimestampAsEpochSeconds() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let epochSeconds = 1783618892.951
        let date = Date(timeIntervalSince1970: epochSeconds)
        let input = SerdeOperationInput(epochSecondsTimestamp: date)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, "{\"epochSecondsTimestamp\":\(epochSeconds)}")
    }

    // MARK: - null

    func test_writeNull_writesNull() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(sparseList: [nil])
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"sparseList":[null]}"#)
    }

    // MARK: - maps

    func test_writeMap_writesAnEmptyMap() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(map: [:])
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"map":{}}"#)
    }

    func test_writeMap_writesAOneElementMap() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(map: ["a": 123])
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"map":{"a":123}}"#)
    }

    func test_writeMap_writesAMultiElementMap() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(map: ["a": 123, "b": 456])
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(
            json,
            #"{"map":{"a":123,"b":456}}"#,
            "Rendered in order to prevent output from triggering recompiles"
        )
    }

    func test_writeMap_writesNestedMaps() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(nestedMap: ["outer": ["inner": "nested"]])
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"nestedMap":{"outer":{"inner":"nested"}}}"#)
    }

    // MARK: - structures

    func test_writeStructure_writesAnEmptyStructure() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(structure: .init())
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"structure":{}}"#)
    }

    func test_writeStructure_writesAStructureWithNonNilMember() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(structure: .init(a: "123"))
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"structure":{"a":"123"}}"#)
    }

    func test_writeStructure_writesAStructureWithMultipleNonNilMembers() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(structure: .init(a: "123", b: 456, c: true))
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        // Structure members do serialize in determinate order, based on how the structure's
        // members are ordered in the schema
        XCTAssertEqual(json, #"{"structure":{"a":"123","b":456,"c":true}}"#)
    }

    // MARK: - unions

    func test_writeUnion_writesAUnionCase() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(union: .x("123"))
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"union":{"x":"123"}}"#)
    }

    func test_writeUnion_writesASDKUnknownUnionCaseAsEmptyUnion() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let input = SerdeOperationInput(union: .sdkUnknown("what"))
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"union":{}}"#)
    }

    // MARK: - documents

    func test_writeDocument_writesABooleanDocumentAsMember() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let document = Document(BooleanDocument(value: true))
        let input = SerdeOperationInput(document: document)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"document":true}"#)
    }

    func test_writeDocument_writesAListDocumentAsRoot() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let document = Document(ListDocument(value: [
            StringDocument(value: "123"),
            IntegerDocument(value: 456),
            DoubleDocument(value: 789.0),
        ]))
        try subject.writeDocument(Smithy.Prelude.documentSchema, document)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"["123",456,789.0]"#)
    }

    func test_writeDocument_writesAListDocumentAsMember() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let document = Document(ListDocument(value: [
            StringDocument(value: "123"),
            IntegerDocument(value: 456),
            DoubleDocument(value: 789.0),
        ]))
        let input = SerdeOperationInput(document: document)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"document":["123",456,789.0]}"#)
    }

    func test_writeDocument_writesAMapDocumentAsRoot() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let document = Document(StringMapDocument(value: [
            "a": StringDocument(value: "123"),
            "b": IntegerDocument(value: 456),
        ]))
        try subject.writeDocument(Smithy.Prelude.documentSchema, document)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(
            json,
            #"{"a":"123","b":456}"#,
            "Rendered in order to prevent output from triggering recompiles"
        )
    }

    func test_writeDocument_writesAMapDocumentAsMember() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let document = Document(StringMapDocument(value: [
            "a": StringDocument(value: "123"),
            "b": IntegerDocument(value: 456),
        ]))
        let input = SerdeOperationInput(document: document)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEquals(
            json,
            #"{"document":{"a":456,"b":"123"}}"#,
            "Rendered in order to prevent output from triggering recompiles"
        )
    }

    func test_writeDocument_writesACustomDocumentTypeAsMember() throws {
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: false)

        let document = Document(BooleanDocument(value: true))
        let input = SerdeOperationInput(myDocument: document)
        try input.serialize(subject)

        let json = String(data: try subject.data, encoding: .utf8)
        XCTAssertEqual(json, #"{"myDocument":true}"#)
    }
}
