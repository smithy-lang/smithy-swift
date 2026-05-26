//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SchemaBasedSerde) import Smithy
@_spi(SchemaBasedSerde) import SmithyCBOR
import AwsCommonRuntimeKit

final class DeserializerTests: XCTestCase {

    func test_double_deserializesIntAsDouble() throws {
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.int(-4321))
        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        let decodedDouble = try subject.readDouble(Prelude.doubleSchema)
        XCTAssertEqual(decodedDouble, -4321.0)
    }

    func test_double_deserializesUIntAsDouble() throws {
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.uint(4321))
        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        let decodedDouble = try subject.readDouble(Prelude.doubleSchema)
        XCTAssertEqual(decodedDouble, 4321.0)
    }

    func test_double_deserializesIntAsFloat() throws {
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.int(-5432))
        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        let decodedFloat = try subject.readFloat(Prelude.floatSchema)
        XCTAssertEqual(decodedFloat, Float(-5432.0))
    }

    func test_double_deserializesUIntAsFloat() throws {
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.uint(5432))
        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        let decodedFloat = try subject.readFloat(Prelude.floatSchema)
        XCTAssertEqual(decodedFloat, Float(5432.0))
    }
}
