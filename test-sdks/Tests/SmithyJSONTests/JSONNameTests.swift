//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SchemaBasedSerde) import SmithyJSON
@_spi(SchemaBasedSerde) import JSONNameTestSDK

final class JSONNameTests: XCTestCase {

    func test_jsonNameSerialize_serializesMemberNameWhenDisabled() throws {
        let subject = Serializer(usesJSONNameTrait: false)
        let input = JSONNameMembersInput(original: "abc")
        try input.serialize(subject)
        let data = try subject.data
        XCTAssertEqual(data, Data(#"{"original":"abc"}"#.utf8))
    }

    func test_jsonNameSerialize_serializesJSONNameWhenEnabled() throws {
        let subject = Serializer(usesJSONNameTrait: true)
        let input = JSONNameMembersInput(original: "abc")
        try input.serialize(subject)
        let data = try subject.data
        XCTAssertEqual(data, Data(#"{"modified":"abc"}"#.utf8))
    }

    func test_jsonNameDeserialize_deserializesMemberNameWhenDisabled() throws {
        let data = Data(#"{"original":"abc"}"#.utf8)
        let subject = try Deserializer(usesJSONNameTrait: false, data: data)
        let output = try JSONNameMembersOutput.deserialize(subject)
        XCTAssertEqual(output.original, "abc")
    }

    func test_jsonNameDeserialize_deserializesJSONNameWhenEnabled() throws {
        let data = Data(#"{"modified":"abc"}"#.utf8)
        let subject = try Deserializer(usesJSONNameTrait: true, data: data)
        let output = try JSONNameMembersOutput.deserialize(subject)
        XCTAssertEqual(output.original, "abc")
    }
}
