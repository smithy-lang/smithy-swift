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
@_spi(SchemaBasedSerde) import MaxRecursionTestSDK

final class RecursionTests: XCTestCase {

    func test_structRecursion_doesNotThrowOnNestedStructAtDepthLimit() throws {
        let cborEncoder = try CBOREncoder()

        // Add 126 allowed levels of CBOR depth
        for _ in 0..<63 {
            cborEncoder.encode(.map_start(1))
            cborEncoder.encode(.text("nestedList"))
            cborEncoder.encode(.array_start(1))
        }

        // Now add a structure with an empty array, to hit the depth limit at 128
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("nestedList"))
        cborEncoder.encode(.array_start(0))

        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        XCTAssertNoThrow(_ = try RecursiveOutput.deserialize(subject))
    }

    func test_structRecursion_throwsOnNestedStructPastDepthLimit() throws {
        let cborEncoder = try CBOREncoder()

        // Add 126 allowed levels of CBOR depth
        for _ in 0..<63 {
            cborEncoder.encode(.map_start(1))
            cborEncoder.encode(.text("nestedList"))
            cborEncoder.encode(.array_start(1))
        }

        // Now add a structure with an array containing an empty map, to exceed the depth limit at 129
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("nestedList"))
        cborEncoder.encode(.array_start(1))
        cborEncoder.encode(.map_start(0))

        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        XCTAssertThrowsError(_ = try RecursiveOutput.deserialize(subject)) { error in
            XCTAssertEqual(
                (error as? CBORDecoderError)?.localizedDescription,
                "Maximum recursive depth exceeded during readStruct()"
            )
        }
    }

    func test_arrayRecursion_doesNotThrowOnNestedArrayAtDepthLimit() throws {
        let cborEncoder = try CBOREncoder()

        // Add the first level of depth
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("nested"))

        // Add 126 allowed levels of CBOR depth, for a total of 127
        for _ in 0..<63 {
            cborEncoder.encode(.map_start(1))
            cborEncoder.encode(.text("nestedList"))
            cborEncoder.encode(.array_start(1))
        }

        // Now add an empty map, to hit the depth limit at 128
        cborEncoder.encode(.map_start(0))

        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        XCTAssertNoThrow(_ = try RecursiveOutput.deserialize(subject))
    }

    func test_arrayRecursion_throwsOnNestedArrayPastDepthLimit() throws {
        let cborEncoder = try CBOREncoder()

        // Add the first level of depth
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("nested"))

        // Add 126 allowed levels of CBOR depth, for a total of 127
        for _ in 0..<63 {
            cborEncoder.encode(.map_start(1))
            cborEncoder.encode(.text("nestedList"))
            cborEncoder.encode(.array_start(1))
        }

        // Now add a map with a nested empty list, to exceed the depth limit at 129
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("nestedList"))
        cborEncoder.encode(.array_start(0))

        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        XCTAssertThrowsError(_ = try RecursiveOutput.deserialize(subject)) { error in
            XCTAssertEqual(
                (error as? CBORDecoderError)?.localizedDescription,
                "Maximum recursive depth exceeded during readList()"
            )
        }
    }

    func test_mapRecursion_doesNotThrowOnNestedMapAtDepthLimit() throws {
        let cborEncoder = try CBOREncoder()

        // Add the first level of depth
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("nested"))

        // Add 126 allowed levels of CBOR depth, for a total of 127
        for _ in 0..<126 {
            cborEncoder.encode(.map_start(1))
            cborEncoder.encode(.text("nestedMap"))
        }

        // Now add an empty map, to hit the depth limit at 128
        cborEncoder.encode(.map_start(0))

        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        XCTAssertNoThrow(_ = try RecursiveOutput.deserialize(subject))
    }

    func test_mapRecursion_throwsOnNestedMapPastDepthLimit() throws {
        let cborEncoder = try CBOREncoder()

        // Add the first level of depth
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("nested"))

        // Add 126 allowed levels of CBOR depth, for a total of 127
        for _ in 0..<126 {
            cborEncoder.encode(.map_start(1))
            cborEncoder.encode(.text("nestedMap"))
        }

        // Now add a map containing a nested empty map, to exceed the depth limit at 129
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("nestedMap"))
        cborEncoder.encode(.array_start(0))

        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        XCTAssertThrowsError(_ = try RecursiveOutput.deserialize(subject)) { error in
            XCTAssertEqual(
                (error as? CBORDecoderError)?.localizedDescription,
                "Maximum recursive depth exceeded during readMap()"
            )
        }
    }

    func test_skipValueRecursion_doesNotThrowOnNestedMapAtDepthLimit() throws {
        let cborEncoder = try CBOREncoder()

        // Add 126 allowed levels of CBOR depth
        for _ in 0..<63 {
            cborEncoder.encode(.map_start(1))
            cborEncoder.encode(.text("differentNestedList"))
            cborEncoder.encode(.array_start(1))
        }

        // Now add a structure with an empty array, to hit the depth limit at 128
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("differentNestedList"))
        cborEncoder.encode(.array_start(0))

        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        XCTAssertNoThrow(_ = try RecursiveOutput.deserialize(subject))
    }

    func test_skipValueRecursion_throwsOnNestedMapPastDepthLimit() throws {
        let cborEncoder = try CBOREncoder()

        // Add 126 allowed levels of CBOR depth
        for _ in 0..<63 {
            cborEncoder.encode(.map_start(1))
            cborEncoder.encode(.text("differentNestedList"))
            cborEncoder.encode(.array_start(1))
        }

        // Now add a structure with an array containing an empty map, to exceed the depth limit at 129
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("differentNestedList"))
        cborEncoder.encode(.array_start(1))
        cborEncoder.encode(.map_start(0))

        let data = Data(cborEncoder.getEncoded())

        let subject = try SmithyCBOR.Deserializer(data: data)
        XCTAssertThrowsError(_ = try RecursiveOutput.deserialize(subject)) { error in
            XCTAssertEqual(
                (error as? CBORDecoderError)?.localizedDescription,
                "Maximum recursive depth exceeded during skipValue()"
            )
        }
    }
}
