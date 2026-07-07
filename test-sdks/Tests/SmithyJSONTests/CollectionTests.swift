//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SchemaBasedSerde) import SmithyJSON
@_spi(SchemaBasedSerde) import AWSJSONTestSDK

final class CollectionTests: XCTestCase {

    func test_list_toleratesNullsInList() throws {
        // Create JSON with list containing both null & nonnull values,
        // and load it in a deserializer
        let data = Data(#"{"list":[123,null,456,null,789,null]}"#.utf8)
        let subject = try Deserializer(usesJSONNameTrait: false, data: data)

        // Deserialize to a structure
        let output = try NullToleranceOutput.deserialize(subject)

        // Verify that list is just the numbers, omitting the nulls
        XCTAssertEqual(output.list, [123, 456, 789])
    }

    func test_map_toleratesNullsAsMapValues() throws {
        // Create JSON with map containing both null & nonnull values,
        // and load it in a deserializer
        let data = Data(#"{"map":{"a":123,"b":null,"c":456,"d":null,"e":789,"f":null}}"#.utf8)
        let subject = try Deserializer(usesJSONNameTrait: false, data: data)

        // Deserialize to a structure
        let output = try NullToleranceOutput.deserialize(subject)

        // Verify that map is just the keys & values for nonnull values
        XCTAssertEqual(output.map, ["a": 123, "c": 456, "e": 789])
    }

    func test_sparseList_readsListWithValuesAndNulls() throws {
        // Create JSON with list containing both null & nonnull values,
        // and load it in a deserializer
        let data = Data(#"{"sparseList":[123,null,456,null,789,null]}"#.utf8)
        let subject = try Deserializer(usesJSONNameTrait: false, data: data)

        // Deserialize to a structure
        let output = try NullToleranceOutput.deserialize(subject)

        // Verify that list contains numbers and nulls
        XCTAssertEqual(output.sparseList, [123, nil, 456, nil, 789, nil])
    }

    func test_sparseMap_readsMapWithValuesAndNulls() throws {
        // Create JSON with map containing both null & nonnull values,
        // and load it in a deserializer
        let data = Data(#"{"sparseMap":{"a":123,"b":null,"c":456,"d":null,"e":789,"f":null}}"#.utf8)
        let subject = try Deserializer(usesJSONNameTrait: false, data: data)

        // Deserialize to a structure
        let output = try NullToleranceOutput.deserialize(subject)

        // Verify that map contains keys & values for null & nonnull values
        XCTAssertEqual(output.sparseMap, ["a": 123, "b": nil, "c": 456, "d": nil, "e": 789, "f": nil])
    }
}
