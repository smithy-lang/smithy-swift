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
@_spi(SchemaBasedSerde) import NullToleranceTestSDK

/// Tests that the CBOR deserializer handles nulls in collections & structures.
///
/// CBOR uses separate code paths for definite & indefinite length collections,
/// so each case is tested in both encodings.
final class CollectionTests: XCTestCase {

    // MARK: - Lists

    func test_list_toleratesNullsInDefiniteList() throws {
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("list"))
        cborEncoder.encode(.array_start(6))
        for value in [123, 456, 789] {
            cborEncoder.encode(.uint(UInt64(value)))
            cborEncoder.encode(.null)
        }

        let subject = try SmithyCBOR.Deserializer(data: Data(cborEncoder.getEncoded()))
        let output = try NullToleranceTestOutput.deserialize(subject)

        // Verify that list is just the numbers, omitting the nulls
        XCTAssertEqual(output.list, [123, 456, 789])
    }

    func test_list_toleratesNullsInIndefiniteList() throws {
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("list"))
        cborEncoder.encode(.indef_array_start)
        for value in [123, 456, 789] {
            cborEncoder.encode(.uint(UInt64(value)))
            cborEncoder.encode(.null)
        }
        cborEncoder.encode(.indef_break)

        let subject = try SmithyCBOR.Deserializer(data: Data(cborEncoder.getEncoded()))
        let output = try NullToleranceTestOutput.deserialize(subject)

        // Verify that list is just the numbers, omitting the nulls
        XCTAssertEqual(output.list, [123, 456, 789])
    }

    func test_sparseList_readsDefiniteListWithValuesAndNulls() throws {
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("sparseList"))
        cborEncoder.encode(.array_start(6))
        for value in [123, 456, 789] {
            cborEncoder.encode(.uint(UInt64(value)))
            cborEncoder.encode(.null)
        }

        let subject = try SmithyCBOR.Deserializer(data: Data(cborEncoder.getEncoded()))
        let output = try NullToleranceTestOutput.deserialize(subject)

        // Verify that list contains numbers and nulls
        XCTAssertEqual(output.sparseList, [123, nil, 456, nil, 789, nil])
    }

    func test_sparseList_readsIndefiniteListWithValuesAndNulls() throws {
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("sparseList"))
        cborEncoder.encode(.indef_array_start)
        for value in [123, 456, 789] {
            cborEncoder.encode(.uint(UInt64(value)))
            cborEncoder.encode(.null)
        }
        cborEncoder.encode(.indef_break)

        let subject = try SmithyCBOR.Deserializer(data: Data(cborEncoder.getEncoded()))
        let output = try NullToleranceTestOutput.deserialize(subject)

        // Verify that list contains numbers and nulls
        XCTAssertEqual(output.sparseList, [123, nil, 456, nil, 789, nil])
    }

    // MARK: - Maps

    func test_map_toleratesNullsAsDefiniteMapValues() throws {
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("map"))
        cborEncoder.encode(.map_start(6))
        encodeMapEntries(cborEncoder)

        let subject = try SmithyCBOR.Deserializer(data: Data(cborEncoder.getEncoded()))
        let output = try NullToleranceTestOutput.deserialize(subject)

        // Verify that map is just the keys & values for nonnull values
        XCTAssertEqual(output.map, ["a": 123, "c": 456, "e": 789])
    }

    func test_map_toleratesNullsAsIndefiniteMapValues() throws {
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("map"))
        cborEncoder.encode(.indef_map_start)
        encodeMapEntries(cborEncoder)
        cborEncoder.encode(.indef_break)

        let subject = try SmithyCBOR.Deserializer(data: Data(cborEncoder.getEncoded()))
        let output = try NullToleranceTestOutput.deserialize(subject)

        // Verify that map is just the keys & values for nonnull values
        XCTAssertEqual(output.map, ["a": 123, "c": 456, "e": 789])
    }

    func test_sparseMap_readsDefiniteMapWithValuesAndNulls() throws {
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("sparseMap"))
        cborEncoder.encode(.map_start(6))
        encodeMapEntries(cborEncoder)

        let subject = try SmithyCBOR.Deserializer(data: Data(cborEncoder.getEncoded()))
        let output = try NullToleranceTestOutput.deserialize(subject)

        // Verify that map contains keys & values for null & nonnull values
        XCTAssertEqual(output.sparseMap, ["a": 123, "b": nil, "c": 456, "d": nil, "e": 789, "f": nil])
    }

    func test_sparseMap_readsIndefiniteMapWithValuesAndNulls() throws {
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("sparseMap"))
        cborEncoder.encode(.indef_map_start)
        encodeMapEntries(cborEncoder)
        cborEncoder.encode(.indef_break)

        let subject = try SmithyCBOR.Deserializer(data: Data(cborEncoder.getEncoded()))
        let output = try NullToleranceTestOutput.deserialize(subject)

        // Verify that map contains keys & values for null & nonnull values
        XCTAssertEqual(output.sparseMap, ["a": 123, "b": nil, "c": 456, "d": nil, "e": 789, "f": nil])
    }

    // MARK: - Structures

    func test_struct_skipsNullMembersInDefiniteMap() throws {
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.map_start(2))
        cborEncoder.encode(.text("list"))
        cborEncoder.encode(.null)
        cborEncoder.encode(.text("map"))
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("a"))
        cborEncoder.encode(.uint(123))

        let subject = try SmithyCBOR.Deserializer(data: Data(cborEncoder.getEncoded()))
        let output = try NullToleranceTestOutput.deserialize(subject)

        // Verify that the null member is left unset & the following member still reads
        XCTAssertNil(output.list)
        XCTAssertEqual(output.map, ["a": 123])
    }

    func test_struct_skipsNullMembersInIndefiniteMap() throws {
        let cborEncoder = try CBOREncoder()
        cborEncoder.encode(.indef_map_start)
        cborEncoder.encode(.text("list"))
        cborEncoder.encode(.null)
        cborEncoder.encode(.text("map"))
        cborEncoder.encode(.map_start(1))
        cborEncoder.encode(.text("a"))
        cborEncoder.encode(.uint(123))
        cborEncoder.encode(.indef_break)

        let subject = try SmithyCBOR.Deserializer(data: Data(cborEncoder.getEncoded()))
        let output = try NullToleranceTestOutput.deserialize(subject)

        // Verify that the null member is left unset & the following member still reads
        XCTAssertNil(output.list)
        XCTAssertEqual(output.map, ["a": 123])
    }

    // MARK: - Helpers

    /// Encodes six map entries that alternate between nonnull & null values.
    private func encodeMapEntries(_ cborEncoder: CBOREncoder) {
        for (key, value) in [("a", 123), ("c", 456), ("e", 789)] {
            cborEncoder.encode(.text(key))
            cborEncoder.encode(.uint(UInt64(value)))
            // Follow each nonnull entry with a null-valued entry
            cborEncoder.encode(.text(nullKey(after: key)))
            cborEncoder.encode(.null)
        }
    }

    private func nullKey(after key: String) -> String {
        switch key {
        case "a": return "b"
        case "c": return "d"
        default: return "f"
        }
    }
}
