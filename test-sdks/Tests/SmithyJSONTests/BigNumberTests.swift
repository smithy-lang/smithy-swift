//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AwsCommonRuntimeKit
@_spi(SchemaBasedSerde) import Smithy
@_spi(SchemaBasedSerde) import SmithyJSON
@_spi(SchemaBasedSerde) import SmithySerialization
@_spi(SchemaBasedSerde) import BigNumTestSDK

/// Tests that `bigInteger` and `bigDecimal` values are written to JSON in full, and read from JSON numbers.
///
/// JSON protocols other than `rpcv2Json` write these types as JSON numbers, and a reader may round a number
/// that its number type can't hold.  So the read tests only use values that a `Double` holds exactly.
final class BigNumberTests: XCTestCase {

    private let bigInteger = "123456789012345678901234567890"

    // 10^20 is beyond Int64 but exactly representable as a Double
    private let largeInteger = "100000000000000000000"

    // MARK: - Serialization

    func test_writeBigInteger_writesAllDigitsAndSign() throws {
        let positive = try serialize(BigNumBodyInput(bigInteger: BigInteger(bigInteger)))
        let negative = try serialize(BigNumBodyInput(bigInteger: BigInteger("-\(bigInteger)")))

        XCTAssertEqual(positive, #"{"bigInteger":123456789012345678901234567890}"#)
        XCTAssertEqual(negative, #"{"bigInteger":-123456789012345678901234567890}"#)
    }

    func test_writeBigDecimal_writesAllDigitsAndPreservesScale() throws {
        XCTAssertEqual(
            try serialize(BigNumBodyInput(bigDecimal: BigDecimal("100000000000000000000001.0"))),
            #"{"bigDecimal":1000000000000000000000010e-1}"#
        )
        XCTAssertEqual(try serialize(BigNumBodyInput(bigDecimal: BigDecimal("1.50"))), #"{"bigDecimal":150e-2}"#)
    }

    func test_writeBigDecimal_writesHugeExponentAsValidJSONNumber() throws {
        let json = try serialize(BigNumBodyInput(bigDecimal: BigDecimal("1e5000")))

        XCTAssertEqual(json, #"{"bigDecimal":1e5000}"#)
    }

    func test_writeBigNumbers_writesDefaultsAndRequiredMembers() throws {
        let input = BigNumBodyInput(requiredBigDecimal: try BigDecimal("2.5"), requiredBigInteger: try BigInteger("7"))

        let json = try serialize(input)

        XCTAssertEqual(
            json,
            #"{"defaultBigDecimal":15e-1,"defaultBigInteger":0,"requiredBigDecimal":25e-1,"requiredBigInteger":7}"#
        )
    }

    func test_writeBigNumbers_writesCollectionsAndUnions() throws {
        let input = BigNumBodyInput(
            list: [try BigInteger("1"), try BigInteger(bigInteger)],
            map: ["a": try BigDecimal("0.5")],
            nested: BigNumClientTypes.BigNumNested(bigInteger: try BigInteger("-9")),
            union: .bigdecimal(try BigDecimal("3.25"))
        )

        let json = try serialize(input)

        XCTAssertEqual(
            json,
            #"{"list":[1,123456789012345678901234567890],"map":{"a":5e-1},"nested":{"bigInteger":-9},"# +
            #""union":{"bigDecimal":325e-2}}"#
        )
    }

    // MARK: - Deserialization

    func test_readBigInteger_readsFullRangeOfInt64() throws {
        XCTAssertEqual(
            try deserialize(#"{"bigInteger":9223372036854775807}"#).bigInteger,
            try BigInteger("9223372036854775807")
        )
        XCTAssertEqual(
            try deserialize(#"{"bigInteger":-9223372036854775808}"#).bigInteger,
            try BigInteger("-9223372036854775808")
        )
    }

    func test_readBigInteger_readsValueBeyondInt64() throws {
        let output = try deserialize(#"{"bigInteger":\#(largeInteger)}"#)

        XCTAssertEqual(output.bigInteger, try BigInteger(largeInteger))
    }

    func test_readBigInteger_readsWholeNumberWrittenInExponentForm() throws {
        let output = try deserialize(#"{"bigInteger":1e20}"#)

        XCTAssertEqual(output.bigInteger, try BigInteger(largeInteger))
    }

    func test_readBigDecimal_readsFractionalValue() throws {
        let output = try deserialize(#"{"bigDecimal":-0.25}"#)

        XCTAssertEqual(output.bigDecimal, try BigDecimal("-0.25"))
    }

    func test_readBigDecimal_readsExponentNotation() throws {
        let output = try deserialize(#"{"bigDecimal":1.5e3}"#)

        XCTAssertEqual(output.bigDecimal, try BigDecimal("1500"))
    }

    func test_readBigNumbers_readsCollectionsNestedStructuresAndUnions() throws {
        let json = #"{"list":[1,\#(largeInteger)],"map":{"a":0.5},"nested":{"bigInteger":-\#(largeInteger)},"# +
            #""union":{"bigDecimal":3.25}}"#

        let output = try deserialize(json)

        XCTAssertEqual(output.list, [try BigInteger("1"), try BigInteger(largeInteger)])
        XCTAssertEqual(output.map, ["a": try BigDecimal("0.5")])
        XCTAssertEqual(output.nested?.bigInteger, try BigInteger("-\(largeInteger)"))
        guard case .bigdecimal(let unionValue) = output.union else { return XCTFail("Expected bigDecimal union member") }
        XCTAssertEqual(unionValue, try BigDecimal("3.25"))
    }

    func test_readBigNumbers_fillsRequiredMembersThatWereNotSent() throws {
        let output = try deserialize("{}")

        XCTAssertEqual(output.requiredBigInteger, try BigInteger("0"))
        XCTAssertEqual(output.requiredBigDecimal, try BigDecimal("0"))
    }

    func test_readBigNumbers_toleratesNullMembers() throws {
        let output = try deserialize(#"{"bigInteger":null,"bigDecimal":null}"#)

        XCTAssertNil(output.bigInteger)
        XCTAssertNil(output.bigDecimal)
    }

    func test_readBigInteger_throwsForNonInteger() throws {
        XCTAssertThrowsError(try deserialize(#"{"bigInteger":1.5}"#))
    }

    func test_readBigInteger_throwsForString() throws {
        XCTAssertThrowsError(try deserialize(#"{"bigInteger":"12"}"#))
    }

    func test_readBigDecimal_throwsForString() throws {
        XCTAssertThrowsError(try deserialize(#"{"bigDecimal":"1.5"}"#))
    }

    // MARK: - Private methods

    private func serialize(_ input: BigNumBodyInput) throws -> String {
        // Omit the defaulted members unless the test expects them
        var input = input
        if input.requiredBigInteger == nil && input.requiredBigDecimal == nil {
            input.defaultBigInteger = nil
            input.defaultBigDecimal = nil
        }
        let subject = SmithyJSON.Serializer(usesJSONNameTrait: true)
        try input.serialize(subject)
        return String(data: try subject.data ?? Data(), encoding: .utf8) ?? ""
    }

    private func deserialize(_ json: String) throws -> BigNumBodyOutput {
        let subject = try SmithyJSON.Deserializer(usesJSONNameTrait: true, data: Data(json.utf8))
        return try BigNumBodyOutput.deserialize(subject)
    }
}
