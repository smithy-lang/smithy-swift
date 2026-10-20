//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SchemaBasedSerde)
import Smithy
@_spi(SchemaBasedSerde)
import SmithySerialization
@_spi(SchemaBasedSerde)
import SmithyJSON
@_spi(SchemaBasedSerde)
import MaxRecursionTestSDK

final class DeeplyNestedTests: XCTestCase {

    func test_serialize_nestsAList() throws {
        let subject = Serializer(usesJSONNameTrait: false)
        let input = DeeplyNestedInput(list: [[["a", "b"]]])
        try input.serialize(subject)
        let string = try String(data: subject.data ?? Data(), encoding: .utf8)
        XCTAssertEqual(string, #"{"list":[[["a","b"]]]}"#)
    }

    func test_serialize_nestsAMap() throws {
        let subject = Serializer(usesJSONNameTrait: false)
        let input = DeeplyNestedInput(map: ["a": ["b": ["c": "d"]]])
        try input.serialize(subject)
        let string = try String(data: subject.data ?? Data(), encoding: .utf8)
        XCTAssertEqual(string, #"{"map":{"a":{"b":{"c":"d"}}}}"#)
    }

    func test_deserialize_nestsAList() throws {
        let original = #"{"list":[[["a","b"]]]}"#
        let subject = try Deserializer(usesJSONNameTrait: false, data: Data(original.utf8))
        let output = try DeeplyNestedOutput.deserialize(subject)
        XCTAssertEqual(output.list, [[["a", "b"]]])
    }

    func test_deserialize_nestsAMap() throws {
        let original = #"{"map":{"a":{"b":{"c":"d"}}}}"#
        let subject = try Deserializer(usesJSONNameTrait: false, data: Data(original.utf8))
        let output = try DeeplyNestedOutput.deserialize(subject)
        XCTAssertEqual(output.map, ["a": ["b": ["c": "d"]]])
    }
}
