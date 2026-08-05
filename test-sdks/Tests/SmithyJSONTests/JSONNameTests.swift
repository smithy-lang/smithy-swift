//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SchemaBasedSerde) import Smithy
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

    // A member with no jsonName trait falls back to the member name in both modes.  The enabled
    // mode reaches that fallback through JSONNameExtension, a separate type from the one the
    // disabled mode uses, so both modes are covered here.

    func test_jsonNameSerialize_serializesMemberNameWithoutJSONNameTraitWhenEnabled() throws {
        let subject = Serializer(usesJSONNameTrait: true)
        try JSONNameMembersInput(unmodified: "abc").serialize(subject)
        XCTAssertEqual(try subject.data, Data(#"{"unmodified":"abc"}"#.utf8))
    }

    func test_jsonNameSerialize_serializesMemberNameWithoutJSONNameTraitWhenDisabled() throws {
        let subject = Serializer(usesJSONNameTrait: false)
        try JSONNameMembersInput(unmodified: "abc").serialize(subject)
        XCTAssertEqual(try subject.data, Data(#"{"unmodified":"abc"}"#.utf8))
    }

    func test_jsonNameSerialize_serializesBothTraitedAndUntraitedMembersWhenEnabled() throws {
        let subject = Serializer(usesJSONNameTrait: true)
        try JSONNameMembersInput(original: "abc", unmodified: "def").serialize(subject)
        XCTAssertEqual(try subject.data, Data(#"{"modified":"abc","unmodified":"def"}"#.utf8))
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

    // MARK: - Cached member name reuse

    // Member schemas are static & shared, and the serializer caches a member's serialized JSON key
    // on the schema the first time that member is written.  Each mode caches into its own schema
    // extension - JSONNameExtension when `usesJSONNameTrait` is enabled, MemberNameExtension when
    // it is disabled - so the value used by whichever serializer writes first must not affect the
    // output of any later serializer using the other setting.

    func test_jsonNameSerialize_doesNotLetADisabledSerializerPoisonTheCacheForAnEnabledOne() throws {
        let input = JSONNameMembersInput(original: "abc")

        // Populate the cache with jsonName disabled, then read it back with jsonName enabled.
        let first = Serializer(usesJSONNameTrait: false)
        try input.serialize(first)
        XCTAssertEqual(try first.data, Data(#"{"original":"abc"}"#.utf8))

        let second = Serializer(usesJSONNameTrait: true)
        try input.serialize(second)
        XCTAssertEqual(try second.data, Data(#"{"modified":"abc"}"#.utf8))
    }

    func test_jsonNameSerialize_doesNotLetAnEnabledSerializerPoisonTheCacheForADisabledOne() throws {
        let input = JSONNameMembersInput(original: "abc")

        // Populate the cache with jsonName enabled, then read it back with jsonName disabled.
        let first = Serializer(usesJSONNameTrait: true)
        try input.serialize(first)
        XCTAssertEqual(try first.data, Data(#"{"modified":"abc"}"#.utf8))

        let second = Serializer(usesJSONNameTrait: false)
        try input.serialize(second)
        XCTAssertEqual(try second.data, Data(#"{"original":"abc"}"#.utf8))
    }

    func test_jsonNameSerialize_reusesTheCachedKeyAcrossRepeatedSerializations() throws {
        // Serializing the same member repeatedly must be stable; the 2nd & later writes read
        // the key from the cache rather than recomputing it.
        for _ in 0..<3 {
            let subject = Serializer(usesJSONNameTrait: true)
            try JSONNameMembersInput(original: "abc").serialize(subject)
            XCTAssertEqual(try subject.data, Data(#"{"modified":"abc"}"#.utf8))
        }
        for _ in 0..<3 {
            let subject = Serializer(usesJSONNameTrait: false)
            try JSONNameMembersInput(original: "abc").serialize(subject)
            XCTAssertEqual(try subject.data, Data(#"{"original":"abc"}"#.utf8))
        }
    }

    func test_jsonNameSerialize_doesNotLetTheModesPoisonEachOtherForAnUntraitedMember() throws {
        // Both modes resolve an untraited member to the same key, but by way of different
        // extensions.  Populate the cache in each order to confirm neither affects the other.
        let input = JSONNameMembersInput(unmodified: "abc")
        let expected = Data(#"{"unmodified":"abc"}"#.utf8)

        let first = Serializer(usesJSONNameTrait: false)
        try input.serialize(first)
        XCTAssertEqual(try first.data, expected)

        // Reads back with the other mode, whose extension is still unpopulated.
        let second = Serializer(usesJSONNameTrait: true)
        try input.serialize(second)
        XCTAssertEqual(try second.data, expected)

        // Both extensions are now cached; confirm each still serves the right key.
        let third = Serializer(usesJSONNameTrait: false)
        try input.serialize(third)
        XCTAssertEqual(try third.data, expected)
    }

    // MARK: - Escaping of cached member names

    // The cached key is built by running the name through the serializer's own string writer, so
    // names containing characters that JSON requires be escaped must come back escaped.  No model
    // in the test SDKs uses such a jsonName, so build the member schema directly.

    func test_jsonNameSerialize_escapesSpecialCharactersInACachedJSONName() throws {
        let member = Schema(
            id: .init("ns.test", "Struct", "plainName"),
            type: .string,
            traits: TraitCollection(traits: [try JSONNameTrait(node: .string("we\"ird\\na\tme"))]),
            containerType: .structure,
            index: 0
        )

        // Serialize twice: the first write computes & caches the key, the second reads it back.
        for _ in 0..<2 {
            let subject = Serializer(usesJSONNameTrait: true)
            try subject.writeString(member, "v")
            XCTAssertEqual(try subject.data, Data(#""we\"ird\\na\tme":"v""#.utf8))
        }

        // The member name itself needs no escaping, and must be unaffected by the above.
        let subject = Serializer(usesJSONNameTrait: false)
        try subject.writeString(member, "v")
        XCTAssertEqual(try subject.data, Data(#""plainName":"v""#.utf8))
    }

    func test_jsonNameSerialize_isThreadSafeWhenBothModesRaceToPopulateTheCache() throws {
        // Both modes race to create & store the cached key on the same shared member schema.
        // Every serialization must still produce the key matching its own setting.
        let expectedWithJSONName = Data(#"{"modified":"abc"}"#.utf8)
        let expectedWithoutJSONName = Data(#"{"original":"abc"}"#.utf8)

        DispatchQueue.concurrentPerform(iterations: 500) { iteration in
            let usesJSONNameTrait = iteration % 2 == 0
            let subject = Serializer(usesJSONNameTrait: usesJSONNameTrait)
            do {
                try JSONNameMembersInput(original: "abc").serialize(subject)
                XCTAssertEqual(
                    try subject.data,
                    usesJSONNameTrait ? expectedWithJSONName : expectedWithoutJSONName
                )
            } catch {
                XCTFail("Serialization failed: \(error)")
            }
        }
    }
}
