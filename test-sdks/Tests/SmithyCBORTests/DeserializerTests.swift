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

    func test_byte_throwsOnOverflowingInt() throws {
        let overflowsInt8 = Int64(Int8.max) + 1
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.int(overflowsInt8))
        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        XCTAssertThrowsError(try subject.readByte(Prelude.byteSchema)) { error in
            XCTAssertEqual((error as? CBORDecoderError)?.localizedDescription, "value \(overflowsInt8) overflows Int8")
        }
    }

    func test_byte_throwsOnOverflowingUInt() throws {
        let overflowsInt8 = UInt64(Int8.max) + 1
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.uint(overflowsInt8))
        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        XCTAssertThrowsError(try subject.readByte(Prelude.byteSchema)) { error in
            XCTAssertEqual((error as? CBORDecoderError)?.localizedDescription, "value \(overflowsInt8) overflows Int8")
        }
    }

    func test_short_throwsOnOverflowingInt() throws {
        let overflowsInt16 = Int64(Int16.max) + 1
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.int(overflowsInt16))
        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        XCTAssertThrowsError(try subject.readShort(Prelude.shortSchema)) { error in
            XCTAssertEqual((error as? CBORDecoderError)?.localizedDescription, "value \(overflowsInt16) overflows Int16")
        }
    }

    func test_short_throwsOnOverflowingUInt() throws {
        let overflowsInt16 = UInt64(Int16.max) + 1
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.uint(overflowsInt16))
        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        XCTAssertThrowsError(try subject.readShort(Prelude.shortSchema)) { error in
            XCTAssertEqual((error as? CBORDecoderError)?.localizedDescription, "value \(overflowsInt16) overflows Int16")
        }
    }

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

    func test_float_deserializesIntAsFloat() throws {
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.int(-5432))
        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        let decodedFloat = try subject.readFloat(Prelude.floatSchema)
        XCTAssertEqual(decodedFloat, Float(-5432.0))
    }

    func test_float_deserializesUIntAsFloat() throws {
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.uint(5432))
        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        let decodedFloat = try subject.readFloat(Prelude.floatSchema)
        XCTAssertEqual(decodedFloat, Float(5432.0))
    }
}
