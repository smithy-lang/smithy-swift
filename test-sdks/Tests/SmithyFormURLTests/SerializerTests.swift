//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SchemaBasedSerde) import Smithy
@_spi(SchemaBasedSerde) import SmithyFormURL
@_spi(SchemaBasedSerde) import SmithySerialization

// Test cases are adapted from the awsQuery & ec2Query protocol tests in smithy-aws-protocol-tests.
final class SerializerTests: XCTestCase {

    // MARK: - Action & Version

    func test_writesActionAndVersionFirst() throws {
        let body = try serialize(.awsQuery, action: "SimpleInputParams", version: "2020-01-08") { schema, s in
            try s.writeString(schema.members[0], "val1")
        }
        XCTAssertEqual(body, "Action=SimpleInputParams&Version=2020-01-08&Foo=val1")
    }

    func test_emptyInputWithoutActionHasNoData() throws {
        let subject = Serializer(variant: .awsQuery)
        try TestStruct(schema: simpleSchema) { _, _ in }.serialize(subject)
        XCTAssertNil(try subject.data)
        XCTAssertNil(subject.mediaType)
    }

    func test_mediaType() throws {
        let subject = Serializer(variant: .awsQuery, action: "A", version: "1")
        XCTAssertEqual(subject.mediaType, "application/x-www-form-urlencoded")
    }

    // MARK: - Simple shapes

    func test_simpleValues() throws {
        for variant in [Serializer.Variant.awsQuery, .ec2Query] {
            let body = try serialize(variant) { schema, s in
                try s.writeString(schema.members[0], "val1")
                try s.writeBoolean(schema.members[2], true)
                try s.writeInteger(schema.members[3], 10)
                try s.writeFloat(schema.members[4], 10.8)
                try s.writeDouble(schema.members[5], 10.8)
                try s.writeBlob(schema.members[6], Data("value".utf8))
                try s.writeLong(schema.members[7], -9_000_000_000)
            }
            XCTAssertEqual(
                body,
                "Foo=val1&Baz=true&Bam=10&FloatValue=10.8&Boo=10.8&Qux=dmFsdWU%3D&Long=-9000000000",
                "\(variant)"
            )
        }
    }

    func test_emptyStringIsWrittenAsEmptyValue() throws {
        for variant in [Serializer.Variant.awsQuery, .ec2Query] {
            let body = try serialize(variant) { schema, s in
                try s.writeString(schema.members[0], "")
                try s.writeString(schema.members[1], "x")
            }
            XCTAssertEqual(body, "Foo=&Bar=x", "\(variant)")
        }
    }

    func test_specialFloatingPointValues() throws {
        let body = try serialize(.awsQuery) { schema, s in
            try s.writeFloat(schema.members[4], .nan)
            try s.writeDouble(schema.members[5], .infinity)
            try s.writeDouble(schema.members[5], -.infinity)
        }
        XCTAssertEqual(body, "FloatValue=NaN&Boo=Infinity&Boo=-Infinity")
    }

    func test_percentEncodesValues() throws {
        let body = try serialize(.awsQuery) { schema, s in
            try s.writeString(schema.members[0], "a b&c=d+e/f~g-h_i.j🐼")
        }
        XCTAssertEqual(body, "Foo=a%20b%26c%3Dd%2Be%2Ff~g-h_i.j%F0%9F%90%BC")
    }

    func test_timestamps() throws {
        let date = Date(timeIntervalSince1970: 1422172800)
        let awsQuery = try serialize(.awsQuery, schema: timestampsSchema) { schema, s in
            try s.writeTimestamp(schema.members[0], date)
            try s.writeTimestamp(schema.members[1], date)
        }
        XCTAssertEqual(awsQuery, "normalFormat=2015-01-25T08%3A00%3A00Z&epochMember=1422172800")
        let ec2Query = try serialize(.ec2Query, schema: timestampsSchema) { schema, s in
            try s.writeTimestamp(schema.members[0], date)
            try s.writeTimestamp(schema.members[1], date)
        }
        XCTAssertEqual(ec2Query, "NormalFormat=2015-01-25T08%3A00%3A00Z&EpochMember=1422172800")
    }

    func test_nullIsNotWritten() throws {
        let body = try serialize(.awsQuery) { schema, s in
            try s.writeNull(schema.members[0])
        }
        XCTAssertEqual(body, "")
    }

    func test_documentThrows() throws {
        let subject = Serializer(variant: .awsQuery)
        XCTAssertThrowsError(try subject.writeDocument(simpleSchema.members[0], Document("x")))
    }

    // MARK: - Member names

    func test_awsQuery_usesXMLNameAndIgnoresEC2QueryName() throws {
        let body = try serialize(.awsQuery, schema: namesSchema) { schema, s in
            for member in schema.members { try s.writeString(member, "v") }
        }
        XCTAssertEqual(body, "hasQueryName=v&xmlAndQueryName=v&xmlNameOnly=v")
    }

    func test_ec2Query_prefersEC2QueryNameThenCapitalizedXMLNameThenCapitalizedMemberName() throws {
        let body = try serialize(.ec2Query, schema: namesSchema) { schema, s in
            for member in schema.members { try s.writeString(member, "v") }
        }
        XCTAssertEqual(body, "HasQueryName=v&queryAndXmlName=v&XmlNameOnly=v")
    }

    // MARK: - Structures

    func test_nestedStructures() throws {
        for (variant, expected) in [
            (Serializer.Variant.awsQuery, "Nested.StringArg=foo&Nested.OtherArg=true&Nested.RecursiveArg.StringArg=baz"),
            (.ec2Query, "Nested.StringArg=foo&Nested.OtherArg=true&Nested.RecursiveArg.StringArg=baz"),
        ] {
            let body = try serialize(variant, schema: nestedSchema) { schema, s in
                try s.writeStruct(schema.members[0], TestStruct(schema: structArgSchema) { schema, s in
                    try s.writeString(schema.members[0], "foo")
                    try s.writeBoolean(schema.members[1], true)
                    try s.writeStruct(schema.members[2], TestStruct(schema: structArgSchema) { schema, s in
                        try s.writeString(schema.members[0], "baz")
                    })
                })
            }
            XCTAssertEqual(body, expected, "\(variant)")
        }
    }

    // MARK: - Lists

    func test_awsQuery_lists() throws {
        let body = try serialize(.awsQuery, schema: listsSchema) { schema, s in
            try writeStringList(s, schema.members[0], ["foo", "bar"])
            try writeGreetingList(s, schema.members[1], ["hello", "hola"])
            try writeStringList(s, schema.members[2], ["A", "B"])
            try writeStringList(s, schema.members[3], ["A", "B"])
            try writeStringList(s, schema.members[4], ["A", "B"])
        }
        XCTAssertEqual(body, [
            "ListArg.member.1=foo&ListArg.member.2=bar",
            "ComplexListArg.member.1.hi=hello&ComplexListArg.member.2.hi=hola",
            "FlattenedListArg.1=A&FlattenedListArg.2=B",
            "ListArgWithXmlNameMember.item.1=A&ListArgWithXmlNameMember.item.2=B",
            "Hi.1=A&Hi.2=B",
        ].joined(separator: "&"))
    }

    func test_ec2Query_listsAreAlwaysFlattened() throws {
        let body = try serialize(.ec2Query, schema: listsSchema) { schema, s in
            try writeStringList(s, schema.members[0], ["foo", "bar"])
            try writeGreetingList(s, schema.members[1], ["hello", "hola"])
            try writeStringList(s, schema.members[3], ["A", "B"])
            try writeStringList(s, schema.members[4], ["A", "B"])
        }
        XCTAssertEqual(body, [
            "ListArg.1=foo&ListArg.2=bar",
            "ComplexListArg.1.Hi=hello&ComplexListArg.2.Hi=hola",
            "ListArgWithXmlNameMember.1=A&ListArgWithXmlNameMember.2=B",
            "Hi.1=A&Hi.2=B",
        ].joined(separator: "&"))
    }

    func test_emptyList() throws {
        let awsQuery = try serialize(.awsQuery, schema: listsSchema) { schema, s in
            try writeStringList(s, schema.members[0], [])
        }
        XCTAssertEqual(awsQuery, "ListArg=")
        let ec2Query = try serialize(.ec2Query, schema: listsSchema) { schema, s in
            try writeStringList(s, schema.members[0], [])
        }
        XCTAssertEqual(ec2Query, "")
    }

    func test_listOfLists_andSiblingsAfterList() throws {
        let body = try serialize(.awsQuery, schema: listsSchema) { schema, s in
            let member = schema.members[5]
            let innerListSchema = member.target!.member
            try s.writeList(member, [["a", "b"], ["c"]]) { inner, s in
                try s.writeList(innerListSchema, inner) { value, s in
                    try s.writeString(innerListSchema.target!.member, value)
                }
            }
            try writeStringList(s, schema.members[0], ["x"])
        }
        XCTAssertEqual(
            body,
            "ListOfLists.member.1.member.1=a&ListOfLists.member.1.member.2=b&ListOfLists.member.2.member.1=c" +
            "&ListArg.member.1=x"
        )
    }

    // MARK: - Maps

    func test_awsQuery_maps() throws {
        let body = try serialize(.awsQuery, schema: mapsSchema) { schema, s in
            try writeStringMap(s, schema.members[0], ["foo": "Foo", "bar": "Bar"])
            try writeStringMap(s, schema.members[1], ["foo": "Foo"])
            try writeStringMap(s, schema.members[2], ["foo": "Foo", "bar": "Bar"])
            try writeStringMap(s, schema.members[3], ["foo": "Foo", "bar": "Bar"])
            try writeStringMap(s, schema.members[4], ["foo": "Foo", "bar": "Bar"])
        }
        XCTAssertEqual(body, [
            "MapArg.entry.1.key=bar&MapArg.entry.1.value=Bar&MapArg.entry.2.key=foo&MapArg.entry.2.value=Foo",
            "Foo.entry.1.key=foo&Foo.entry.1.value=Foo",
            "MapWithXmlMemberName.entry.1.K=bar&MapWithXmlMemberName.entry.1.V=Bar" +
                "&MapWithXmlMemberName.entry.2.K=foo&MapWithXmlMemberName.entry.2.V=Foo",
            "FlattenedMap.1.key=bar&FlattenedMap.1.value=Bar&FlattenedMap.2.key=foo&FlattenedMap.2.value=Foo",
            "Hi.1.K=bar&Hi.1.V=Bar&Hi.2.K=foo&Hi.2.V=Foo",
        ].joined(separator: "&"))
    }

    func test_awsQuery_mapOfLists() throws {
        let body = try serialize(.awsQuery, schema: mapsSchema) { schema, s in
            let member = schema.members[5]
            let valueSchema = member.target!.value
            try s.writeMap(member, ["foo": ["A", "B"], "bar": ["C", "D"]]) { list, s in
                try s.writeList(valueSchema, list) { value, s in
                    try s.writeString(valueSchema.target!.member, value)
                }
            }
        }
        XCTAssertEqual(
            body,
            "MapOfLists.entry.1.key=bar&MapOfLists.entry.1.value.member.1=C&MapOfLists.entry.1.value.member.2=D" +
            "&MapOfLists.entry.2.key=foo&MapOfLists.entry.2.value.member.1=A&MapOfLists.entry.2.value.member.2=B"
        )
    }

    func test_emptyMapIsNotWritten() throws {
        let body = try serialize(.awsQuery, schema: mapsSchema) { schema, s in
            try writeStringMap(s, schema.members[0], [:])
        }
        XCTAssertEqual(body, "")
    }

    // MARK: - Helpers

    private func serialize(
        _ variant: Serializer.Variant,
        action: String? = nil,
        version: String? = nil,
        schema: Schema? = nil,
        _ members: @escaping (Schema, any ShapeSerializer) throws -> Void
    ) throws -> String {
        let subject = Serializer(variant: variant, action: action, version: version)
        try TestStruct(schema: schema ?? simpleSchema, members: members).serialize(subject)
        return String(decoding: try subject.data ?? Data(), as: UTF8.self)
    }
}

// MARK: - Test types & schemas

private func writeStringList(_ s: any ShapeSerializer, _ member: Schema, _ value: [String]) throws {
    let elementSchema = member.target!.member
    try s.writeList(member, value) { try $1.writeString(elementSchema, $0) }
}

private func writeGreetingList(_ s: any ShapeSerializer, _ member: Schema, _ value: [String]) throws {
    let elementSchema = member.target!.member
    try s.writeList(member, value) { hi, s in
        try s.writeStruct(elementSchema, TestStruct(schema: greetingSchema) { schema, s in
            try s.writeString(schema.members[0], hi)
        })
    }
}

private func writeStringMap(_ s: any ShapeSerializer, _ member: Schema, _ value: [String: String]) throws {
    let valueSchema = member.target!.value
    try s.writeMap(member, value) { try $1.writeString(valueSchema, $0) }
}


private struct TestStruct: SerializableStruct {
    let schema: Schema
    let members: (Schema, any ShapeSerializer) throws -> Void

    func serialize(_ serializer: any ShapeSerializer) throws {
        try serializer.writeStruct(schema, self)
    }

    func serializeMembers(_ schema: Schema, _ serializer: any ShapeSerializer) throws {
        try members(schema, serializer)
    }
}

private let ns = "smithy.swift.formurl.test"

private func structure(_ name: String, _ members: [(String, Schema, TraitCollection)]) -> Schema {
    Schema(
        id: ShapeID(ns, name),
        type: .structure,
        members: members.enumerated().map { index, member in
            Schema(
                id: ShapeID(ns, name, member.0),
                type: member.1.type,
                traits: member.2,
                containerType: .structure,
                target: member.1,
                index: index
            )
        }
    )
}

private func list(_ name: String, _ element: Schema, _ traits: TraitCollection = []) -> Schema {
    Schema(
        id: ShapeID(ns, name),
        type: .list,
        members: [
            Schema(id: ShapeID(ns, name, "member"), type: element.type, traits: traits,
                   containerType: .list, target: element, index: 0),
        ]
    )
}

private func map(
    _ name: String,
    _ value: Schema,
    keyTraits: TraitCollection = [],
    valueTraits: TraitCollection = []
) -> Schema {
    Schema(
        id: ShapeID(ns, name),
        type: .map,
        members: [
            Schema(id: ShapeID(ns, name, "key"), type: .string, traits: keyTraits,
                   containerType: .map, target: Prelude.stringSchema, index: 0),
            Schema(id: ShapeID(ns, name, "value"), type: value.type, traits: valueTraits,
                   containerType: .map, target: value, index: 1),
        ]
    )
}

private func xmlName(_ name: String) -> XMLNameTrait? { try? XMLNameTrait(node: .string(name)) }
private func ec2QueryName(_ name: String) -> EC2QueryNameTrait? { try? EC2QueryNameTrait(node: .string(name)) }
private let xmlFlattened = try? XMLFlattenedTrait(node: [:])
private let epochSeconds = try? TimestampFormatTrait(node: "epoch-seconds")

private let simpleSchema = structure("SimpleInputParamsInput", [
    ("Foo", Prelude.stringSchema, []),
    ("Bar", Prelude.stringSchema, []),
    ("Baz", Prelude.booleanSchema, []),
    ("Bam", Prelude.integerSchema, []),
    ("FloatValue", Prelude.floatSchema, []),
    ("Boo", Prelude.doubleSchema, []),
    ("Qux", Prelude.blobSchema, []),
    ("Long", Prelude.longSchema, []),
])

private let timestampsSchema = structure("QueryTimestampsInput", [
    ("normalFormat", Prelude.timestampSchema, []),
    ("epochMember", Prelude.timestampSchema, [epochSeconds]),
])

private let namesSchema = structure("NamesInput", [
    ("hasQueryName", Prelude.stringSchema, [ec2QueryName("HasQueryName")]),
    ("DistinctQueryAndXmlName", Prelude.stringSchema, [ec2QueryName("queryAndXmlName"), xmlName("xmlAndQueryName")]),
    ("DistinctXmlName", Prelude.stringSchema, [xmlName("xmlNameOnly")]),
])

private let structArgSchema: Schema = Schema(
    id: ShapeID(ns, "StructArg"),
    type: .structure,
    members: [
        Schema(id: ShapeID(ns, "StructArg", "StringArg"), type: .string,
               containerType: .structure, target: Prelude.stringSchema, index: 0),
        Schema(id: ShapeID(ns, "StructArg", "OtherArg"), type: .boolean,
               containerType: .structure, target: Prelude.booleanSchema, index: 1),
        Schema(id: ShapeID(ns, "StructArg", "RecursiveArg"), type: .structure,
               containerType: .structure, target: structArgSchema, index: 2),
    ]
)

private let nestedSchema = structure("NestedStructuresInput", [("Nested", structArgSchema, [])])

private let greetingSchema = structure("GreetingStruct", [("hi", Prelude.stringSchema, [])])
private let stringListSchema = list("StringList", Prelude.stringSchema)
private let listWithXMLNameSchema = list("ListWithXmlName", Prelude.stringSchema, [xmlName("item")])

private let listsSchema = structure("QueryListsInput", [
    ("ListArg", stringListSchema, []),
    ("ComplexListArg", list("GreetingList", greetingSchema), []),
    ("FlattenedListArg", stringListSchema, [xmlFlattened]),
    ("ListArgWithXmlNameMember", listWithXMLNameSchema, []),
    ("FlattenedListArgWithXmlName", listWithXMLNameSchema, [xmlFlattened, xmlName("Hi")]),
    ("ListOfLists", list("ListOfLists", stringListSchema), []),
])

private let stringMapSchema = map("StringMap", Prelude.stringSchema)
private let mapWithXMLNameSchema = map(
    "MapWithXmlName",
    Prelude.stringSchema,
    keyTraits: [xmlName("K")],
    valueTraits: [xmlName("V")]
)

private let mapsSchema = structure("QueryMapsInput", [
    ("MapArg", stringMapSchema, []),
    ("RenamedMapArg", stringMapSchema, [xmlName("Foo")]),
    ("MapWithXmlMemberName", mapWithXMLNameSchema, []),
    ("FlattenedMap", stringMapSchema, [xmlFlattened]),
    ("FlattenedMapWithXmlName", mapWithXMLNameSchema, [xmlFlattened, xmlName("Hi")]),
    ("MapOfLists", map("MapOfLists", stringListSchema), []),
])
