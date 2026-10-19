//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AwsCommonRuntimeKit
@_spi(SchemaBasedSerde) import Smithy
@_spi(SchemaBasedSerde) import SmithyHTTPAPI
@_spi(SchemaBasedSerde) import SmithySerialization
@_spi(SchemaBasedSerde) @testable import BigNumTestSDK

/// Tests that `bigInteger` and `bigDecimal` values are bound to HTTP headers, query strings and labels
/// as plain decimal text, and read back from headers without loss of precision.
final class BigNumberBindingTests: XCTestCase {

    private let bigInteger = "123456789012345678901234567890"
    private let operation = BigNumClient.bigNumHTTPOperation

    // MARK: - Headers

    func test_header_serializesBigInteger() throws {
        let subject = HTTPHeaderSerializer()

        try BigNumHTTPInput(headerBigInteger: BigInteger("-\(bigInteger)"))
            .serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Big-Integer"), ["-\(bigInteger)"])
    }

    func test_header_serializesBigDecimal() throws {
        let subject = HTTPHeaderSerializer()

        try BigNumHTTPInput(headerBigDecimal: BigDecimal("100000000000000000000001.0"))
            .serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.headers.values(for: "X-Big-Decimal"), ["1000000000000000000000010e-1"])
    }

    func test_header_deserializesBigInteger() throws {
        let output = try deserialize(["X-Big-Integer": "-\(bigInteger)"])

        XCTAssertEqual(output.headerBigInteger, try BigInteger("-\(bigInteger)"))
    }

    func test_header_deserializesBigDecimalWithoutLosingDigitsOrScale() throws {
        let output = try deserialize(["X-Big-Decimal": "0.100000000000000000000001"])
        XCTAssertEqual(output.headerBigDecimal, try BigDecimal("0.100000000000000000000001"))

        let withScale = try deserialize(["X-Big-Decimal": "1.50"])
        XCTAssertEqual(withScale.headerBigDecimal, try BigDecimal("1.50"))
    }

    func test_header_throwsForInvalidNumbers() throws {
        XCTAssertThrowsError(try deserialize(["X-Big-Integer": "1.5"]))
        XCTAssertThrowsError(try deserialize(["X-Big-Integer": "abc"]))
        XCTAssertThrowsError(try deserialize(["X-Big-Decimal": "abc"]))
    }

    // MARK: - Query

    func test_query_serializesBigNumbers() throws {
        let subject = HTTPQuerySerializer()

        try BigNumHTTPInput(
            queryBigDecimal: BigDecimal("-0.100000000000000000000001"),
            queryBigInteger: BigInteger(bigInteger)
        ).serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(Set(subject.queryItems), Set([
            URIQueryItem(name: "bigInteger", value: bigInteger),
            URIQueryItem(name: "bigDecimal", value: "-100000000000000000000001e-24"),
        ]))
    }

    // MARK: - Labels

    func test_label_serializesBigInteger() throws {
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        try BigNumHTTPInput(label: BigInteger("-\(bigInteger)")).serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/http/-\(bigInteger)")
    }

    // MARK: - Private methods

    private func deserialize(_ headers: [String: String]) throws -> BigNumHTTPOutput {
        try BigNumHTTPOutput.deserialize(HTTPHeaderDeserializer(headers: Headers(headers)))
    }
}
