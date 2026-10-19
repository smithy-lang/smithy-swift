//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AwsCommonRuntimeKit
@_spi(SchemaBasedSerde) import Smithy
@_spi(SchemaBasedSerde) import SmithyCBOR
@_spi(SchemaBasedSerde) import SmithySerialization
@_spi(SchemaBasedSerde) import BigNumTestSDK

/// Tests that `bigInteger` and `bigDecimal` values are written to and read from CBOR as bignums (tags 2 & 3)
/// and decimal fractions (tag 4).
final class BigNumberTests: XCTestCase {

    private let bigInteger = "123456789012345678901234567890"

    // MARK: - Serialization

    func test_writeBigInteger_writesBignumForValueBeyondUInt64() throws {
        let expected = try BigInteger(bigInteger)

        let decoded = try serialize(BigNumBodyInput(bigInteger: BigInteger(bigInteger)))

        XCTAssertEqual(decoded, .map(["bigInteger": .bigInteger(expected)]))
    }

    func test_writeBigDecimal_writesDecimalFraction() throws {
        let expected = try BigDecimal("0.100000000000000000000001")

        let decoded = try serialize(BigNumBodyInput(bigDecimal: BigDecimal("0.100000000000000000000001")))

        XCTAssertEqual(decoded, .map(["bigDecimal": .bigDecimal(expected)]))
    }

    // MARK: - Deserialization

    func test_readBigInteger_readsBignumBeyondUInt64() throws {
        let output = try deserialize(memberName: "bigInteger", .bigInteger(BigInteger(bigInteger)))

        XCTAssertEqual(output.bigInteger, try BigInteger(bigInteger))
    }

    func test_readBigInteger_readsUnsignedInteger() throws {
        let output = try deserialize(memberName: "bigInteger", .uint(UInt64.max))

        XCTAssertEqual(output.bigInteger, try BigInteger("18446744073709551615"))
    }

    func test_readBigInteger_readsNegativeInteger() throws {
        let output = try deserialize(memberName: "bigInteger", .int(-42))

        XCTAssertEqual(output.bigInteger, try BigInteger("-42"))
    }

    func test_readBigInteger_throwsForText() throws {
        XCTAssertThrowsError(try deserialize(memberName: "bigInteger", .text("12")))
    }

    func test_readBigInteger_throwsForDouble() throws {
        XCTAssertThrowsError(try deserialize(memberName: "bigInteger", .double(1.5)))
    }

    func test_readBigDecimal_readsDecimalFractionWithMoreDigitsThanDoubleCanHold() throws {
        let output = try deserialize(
            memberName: "bigDecimal",
            .bigDecimal(BigDecimal("100000000000000000000001.0"))
        )

        XCTAssertEqual(output.bigDecimal, try BigDecimal("100000000000000000000001.0"))
    }

    func test_readBigDecimal_readsInteger() throws {
        XCTAssertEqual(
            try deserialize(memberName: "bigDecimal", .uint(7)).bigDecimal,
            try BigDecimal("7")
        )
        XCTAssertEqual(
            try deserialize(memberName: "bigDecimal", .int(-7)).bigDecimal,
            try BigDecimal("-7")
        )
    }

    func test_readBigDecimal_readsBignum() throws {
        let output = try deserialize(memberName: "bigDecimal", .bigInteger(BigInteger(bigInteger)))

        XCTAssertEqual(output.bigDecimal, try BigDecimal(bigInteger))
    }

    func test_readBigDecimal_readsDouble() throws {
        let output = try deserialize(memberName: "bigDecimal", .double(1.5))

        XCTAssertEqual(output.bigDecimal, try BigDecimal("1.5"))
    }

    func test_readBigDecimal_throwsForText() throws {
        XCTAssertThrowsError(try deserialize(memberName: "bigDecimal", .text("1.5")))
    }

    func test_readBigNumbers_roundTripsThroughSerializerAndDeserializer() throws {
        let input = BigNumBodyInput(
            bigDecimal: try BigDecimal("-0.100000000000000000000001"),
            bigInteger: try BigInteger(bigInteger),
            list: [try BigInteger("1"), try BigInteger("-\(bigInteger)")],
            map: ["a": try BigDecimal("1.50")],
            nested: BigNumClientTypes.BigNumNested(bigInteger: try BigInteger("-9")),
            requiredBigDecimal: try BigDecimal("2.5"),
            requiredBigInteger: try BigInteger("7"),
            union: .bigdecimal(try BigDecimal("3.25"))
        )
        let serializer = try SmithyCBOR.Serializer()
        try input.serialize(serializer)

        let output = try BigNumBodyOutput.deserialize(SmithyCBOR.Deserializer(data: try XCTUnwrap(serializer.data)))

        XCTAssertEqual(output.bigDecimal, input.bigDecimal)
        XCTAssertEqual(output.bigInteger, input.bigInteger)
        XCTAssertEqual(output.list, input.list)
        XCTAssertEqual(output.map, input.map)
        XCTAssertEqual(output.nested?.bigInteger, input.nested?.bigInteger)
        XCTAssertEqual(output.requiredBigDecimal, input.requiredBigDecimal)
        XCTAssertEqual(output.requiredBigInteger, input.requiredBigInteger)
        XCTAssertEqual(output.defaultBigDecimal, input.defaultBigDecimal)
        XCTAssertEqual(output.defaultBigInteger, input.defaultBigInteger)
        guard case .bigdecimal(let unionValue) = output.union else { return XCTFail("Expected bigDecimal union member") }
        XCTAssertEqual(unionValue, try BigDecimal("3.25"))
    }

    func test_skipValue_skipsBignumsInUnknownMembers() throws {
        let encoder = try CBOREncoder()
        encoder.encode(.map_start(2))
        encoder.encode(.text("unknownBignum"))
        encoder.encode(.bigInteger(try BigInteger(bigInteger)))
        encoder.encode(.text("bigInteger"))
        encoder.encode(.uint(5))

        let output = try BigNumBodyOutput.deserialize(SmithyCBOR.Deserializer(data: Data(encoder.getEncoded())))

        XCTAssertEqual(output.bigInteger, try BigInteger("5"))
    }

    // MARK: - Private methods

    private func serialize(_ input: BigNumBodyInput) throws -> CBORType {
        var input = input
        input.defaultBigInteger = nil
        input.defaultBigDecimal = nil
        let subject = try SmithyCBOR.Serializer()
        try input.serialize(subject)
        return try CBORDecoder(data: Array(try XCTUnwrap(subject.data))).popNext()
    }

    private func deserialize(memberName: String, _ value: CBORType) throws -> BigNumBodyOutput {
        let encoder = try CBOREncoder()
        encoder.encode(.map_start(1))
        encoder.encode(.text(memberName))
        encoder.encode(value)
        return try BigNumBodyOutput.deserialize(SmithyCBOR.Deserializer(data: Data(encoder.getEncoded())))
    }
}
