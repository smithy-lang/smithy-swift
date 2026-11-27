//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(SchemaBasedSerde) @_spi(SmithyDocumentImpl) import Smithy
@_spi(SchemaBasedSerde) import SmithySerialization
@_spi(SchemaBasedSerde) import SmithyXML
import XCTest

// Expected bodies are adapted from the restXml request tests in smithy-aws-protocol-tests,
// without the whitespace between elements.
final class SerializerTests: XCTestCase {

    // MARK: - Simple shapes

    func test_scalars_itWritesEveryScalarType() throws {
        let schema = structure("SimpleScalarPropertiesRequest", [
            ("stringValue", [], Prelude.stringSchema),
            ("trueBooleanValue", [], Prelude.booleanSchema),
            ("falseBooleanValue", [], Prelude.booleanSchema),
            ("byteValue", [], Prelude.byteSchema),
            ("shortValue", [], Prelude.shortSchema),
            ("integerValue", [], Prelude.integerSchema),
            ("longValue", [], Prelude.longSchema),
            ("floatValue", [], Prelude.floatSchema),
            ("doubleValue", [trait(XMLNameTrait.self, "DoubleDribble")], Prelude.doubleSchema),
            ("bigIntegerValue", [], Prelude.bigIntegerSchema),
            ("bigDecimalValue", [], Prelude.bigDecimalSchema),
        ])
        let value = TestStruct(schema) { schema, serializer in
            try serializer.writeString(schema.members[0], "string")
            try serializer.writeBoolean(schema.members[1], true)
            try serializer.writeBoolean(schema.members[2], false)
            try serializer.writeByte(schema.members[3], 1)
            try serializer.writeShort(schema.members[4], 2)
            try serializer.writeInteger(schema.members[5], 3)
            try serializer.writeLong(schema.members[6], 4)
            try serializer.writeFloat(schema.members[7], 5.5)
            try serializer.writeDouble(schema.members[8], 6.5)
            try serializer.writeBigInteger(schema.members[9], 7)
            try serializer.writeBigDecimal(schema.members[10], 8.25)
        }

        XCTAssertEqual(try serialize(value), "<SimpleScalarPropertiesRequest>" +
            "<stringValue>string</stringValue><trueBooleanValue>true</trueBooleanValue>" +
            "<falseBooleanValue>false</falseBooleanValue><byteValue>1</byteValue><shortValue>2</shortValue>" +
            "<integerValue>3</integerValue><longValue>4</longValue><floatValue>5.5</floatValue>" +
            "<DoubleDribble>6.5</DoubleDribble><bigIntegerValue>7</bigIntegerValue>" +
            "<bigDecimalValue>8.25</bigDecimalValue>" +
            "</SimpleScalarPropertiesRequest>")
    }

    func test_floatingPoint_itWritesNonFiniteValues() throws {
        let schema = structure("FloatsRequest", [
            ("nan", [], Prelude.doubleSchema),
            ("inf", [], Prelude.doubleSchema),
            ("negInf", [], Prelude.floatSchema),
        ])
        let value = TestStruct(schema) { schema, serializer in
            try serializer.writeDouble(schema.members[0], .nan)
            try serializer.writeDouble(schema.members[1], .infinity)
            try serializer.writeFloat(schema.members[2], -.infinity)
        }

        XCTAssertEqual(try serialize(value),
            "<FloatsRequest><nan>NaN</nan><inf>Infinity</inf><negInf>-Infinity</negInf></FloatsRequest>")
    }

    func test_timestamps_itWritesEachTimestampFormat() throws {
        let schema = structure("XmlTimestampsRequest", [
            ("normal", [], Prelude.timestampSchema),
            ("epochSeconds", [trait(TimestampFormatTrait.self, "epoch-seconds")], Prelude.timestampSchema),
            ("httpDate", [trait(TimestampFormatTrait.self, "http-date")], Prelude.timestampSchema),
        ])
        let date = Date(timeIntervalSince1970: 1398796238)
        let value = TestStruct(schema) { schema, serializer in
            for member in schema.members { try serializer.writeTimestamp(member, date) }
        }

        XCTAssertEqual(try serialize(value), "<XmlTimestampsRequest>" +
            "<normal>2014-04-29T18:30:38Z</normal><epochSeconds>1398796238</epochSeconds>" +
            "<httpDate>Tue, 29 Apr 2014 18:30:38 GMT</httpDate>" +
            "</XmlTimestampsRequest>")
    }

    func test_blobs_itWritesBase64() throws {
        let schema = structure("XmlBlobsRequest", [("data", [], Prelude.blobSchema)])
        let value = TestStruct(schema) { schema, serializer in
            try serializer.writeBlob(schema.members[0], Data("value".utf8))
        }

        XCTAssertEqual(try serialize(value), "<XmlBlobsRequest><data>dmFsdWU=</data></XmlBlobsRequest>")
    }

    func test_strings_itEscapesText() throws {
        let schema = structure("EscapesRequest", [("value", [], Prelude.stringSchema)])
        let value = TestStruct(schema) { schema, serializer in
            try serializer.writeString(schema.members[0], "<a> & \"b\" 'c'\r\n\t世界")
        }

        XCTAssertEqual(try serialize(value),
            "<EscapesRequest><value>&lt;a&gt; &amp; \"b\" 'c'&#xD;\n\t世界</value></EscapesRequest>")
    }

    func test_strings_itWritesEmptyStrings() throws {
        let schema = structure("XmlEmptyStringsRequest", [("emptyString", [], Prelude.stringSchema)])
        let value = TestStruct(schema) { schema, serializer in
            try serializer.writeString(schema.members[0], "")
        }

        XCTAssertEqual(try serialize(value),
            "<XmlEmptyStringsRequest><emptyString></emptyString></XmlEmptyStringsRequest>")
    }

    func test_null_itOmitsNulls() throws {
        let schema = structure("NullsRequest", [("value", [], Prelude.stringSchema)])
        let value = TestStruct(schema) { schema, serializer in
            try serializer.writeNull(schema.members[0])
        }

        XCTAssertEqual(try serialize(value), "<NullsRequest></NullsRequest>")
    }

    func test_documents_itThrows() {
        let schema = structure("DocumentsRequest", [("value", [], Prelude.documentSchema)])
        let value = TestStruct(schema) { schema, serializer in
            try serializer.writeDocument(schema.members[0], StringDocument(value: "x"))
        }

        XCTAssertThrowsError(try serialize(value))
    }

    // MARK: - Structures & unions

    func test_struct_itWritesNestedStructures() throws {
        let inner = structure("Inner", [("hi", [], Prelude.stringSchema)])
        let schema = structure("NestedRequest", [("nested", [], inner)])
        let value = TestStruct(schema) { schema, serializer in
            try serializer.writeStruct(schema.members[0], TestStruct(inner) { schema, serializer in
                try serializer.writeString(schema.members[0], "there")
            })
        }

        XCTAssertEqual(try serialize(value), "<NestedRequest><nested><hi>there</hi></nested></NestedRequest>")
    }

    func test_struct_itUsesTheShapeXMLNameForTheRootElement() throws {
        let schema = structure("Renamed", [], traits: [trait(XMLNameTrait.self, "Hello")])

        XCTAssertEqual(try serialize(TestStruct(schema) { _, _ in }), "<Hello></Hello>")
    }

    func test_union_itWritesTheSetMember() throws {
        let union = Schema(
            id: .init("test", "XmlUnionShape"),
            type: .union,
            members: [
                member("XmlUnionShape", "stringValue", 0, containerType: .union, Prelude.stringSchema),
                member("XmlUnionShape", "intValue", 1, containerType: .union, Prelude.integerSchema),
            ]
        )
        let schema = structure("XmlUnionsRequest", [("unionValue", [], union)])
        let value = TestStruct(schema) { schema, serializer in
            try serializer.writeStruct(schema.members[0], TestStruct(union) { schema, serializer in
                try serializer.writeInteger(schema.members[1], 5)
            })
        }

        XCTAssertEqual(try serialize(value),
            "<XmlUnionsRequest><unionValue><intValue>5</intValue></unionValue></XmlUnionsRequest>")
    }

    // MARK: - Lists

    func test_list_itWritesListsPerTheXmlListsTest() throws {
        let item = structure("StructureListMember", [
            ("a", [trait(XMLNameTrait.self, "value")], Prelude.stringSchema),
            ("b", [trait(XMLNameTrait.self, "other")], Prelude.stringSchema),
        ])
        let stringList = list("StringList", Prelude.stringSchema)
        let renamedList = list("RenamedList", memberTraits: [trait(XMLNameTrait.self, "item")], Prelude.stringSchema)
        let nestedList = list("NestedStringList", stringList)
        let structureList = list("StructureList", memberTraits: [trait(XMLNameTrait.self, "item")], item)
        let schema = structure("XmlListsRequest", [
            ("stringList", [], stringList),
            ("nestedStringList", [], nestedList),
            ("renamed", [trait(XMLNameTrait.self, "renamed")], renamedList),
            ("flattenedList", [trait(XMLFlattenedTrait.self)], renamedList),
            ("flattenedList2", [trait(XMLFlattenedTrait.self), trait(XMLNameTrait.self, "customName")], stringList),
            ("myStructureList", [], structureList),
            ("flattenedStructureList", [trait(XMLFlattenedTrait.self)], structureList),
        ])
        func writeItem(_ a: String, _ b: String) -> TestStruct {
            TestStruct(item) { schema, serializer in
                try serializer.writeString(schema.members[0], a)
                try serializer.writeString(schema.members[1], b)
            }
        }
        let value = TestStruct(schema) { schema, serializer in
            try writeStrings(serializer, schema.members[0], ["foo", "bar"])
            let inner = schema.members[1].target!.member
            try serializer.writeList(schema.members[1], [["foo", "bar"], ["baz", "qux"]]) { value, serializer in
                try writeStrings(serializer, inner, value)
            }
            try writeStrings(serializer, schema.members[2], ["foo", "bar"])
            try writeStrings(serializer, schema.members[3], ["hi", "bye"])
            try writeStrings(serializer, schema.members[4], ["yep", "nope"])
            let structMember = schema.members[5].target!.member
            try serializer.writeList(schema.members[5], [("1", "2"), ("3", "4")]) { value, serializer in
                try serializer.writeStruct(structMember, writeItem(value.0, value.1))
            }
            try serializer.writeList(schema.members[6], [("5", "6"), ("7", "8")]) { value, serializer in
                try serializer.writeStruct(structMember, writeItem(value.0, value.1))
            }
        }

        XCTAssertEqual(try serialize(value), "<XmlListsRequest>" +
            "<stringList><member>foo</member><member>bar</member></stringList>" +
            "<nestedStringList><member><member>foo</member><member>bar</member></member>" +
            "<member><member>baz</member><member>qux</member></member></nestedStringList>" +
            "<renamed><item>foo</item><item>bar</item></renamed>" +
            "<flattenedList>hi</flattenedList><flattenedList>bye</flattenedList>" +
            "<customName>yep</customName><customName>nope</customName>" +
            "<myStructureList><item><value>1</value><other>2</other></item>" +
            "<item><value>3</value><other>4</other></item></myStructureList>" +
            "<flattenedStructureList><value>5</value><other>6</other></flattenedStructureList>" +
            "<flattenedStructureList><value>7</value><other>8</other></flattenedStructureList>" +
            "</XmlListsRequest>")
    }

    func test_list_itWritesEmptyListsAsEmptyElementsAndOmitsEmptyFlattenedLists() throws {
        let stringList = list("StringList", Prelude.stringSchema)
        let schema = structure("XmlEmptyListsRequest", [
            ("stringList", [], stringList),
            ("flattened", [trait(XMLFlattenedTrait.self)], stringList),
        ])
        let value = TestStruct(schema) { schema, serializer in
            try writeStrings(serializer, schema.members[0], [])
            try writeStrings(serializer, schema.members[1], [])
        }

        XCTAssertEqual(try serialize(value), "<XmlEmptyListsRequest><stringList></stringList></XmlEmptyListsRequest>")
    }

    func test_list_itOmitsNullItemsOfSparseLists() throws {
        let schema = structure("SparseRequest", [("values", [], list("SparseList", Prelude.stringSchema))])
        let value = TestStruct(schema) { schema, serializer in
            let item = schema.members[0].target!.member
            try serializer.writeSparseList(schema.members[0], ["a", nil, "b"]) { value, serializer in
                try serializer.writeString(item, value)
            }
        }

        XCTAssertEqual(try serialize(value),
            "<SparseRequest><values><member>a</member><member>b</member></values></SparseRequest>")
    }

    // MARK: - Maps

    func test_map_itWritesWrappedMapsInKeyOrder() throws {
        let schema = structure("XmlMapsRequest", [("myMap", [], map("StringMap"))])
        let value = TestStruct(schema) { schema, serializer in
            try writeStringMap(serializer, schema.members[0], ["foo": "Foo", "baz": "Baz"])
        }

        XCTAssertEqual(try serialize(value), "<XmlMapsRequest><myMap>" +
            "<entry><key>baz</key><value>Baz</value></entry><entry><key>foo</key><value>Foo</value></entry>" +
            "</myMap></XmlMapsRequest>")
    }

    func test_map_itWritesMapsWithRenamedKeysAndStructureValues() throws {
        let greeting = structure("GreetingStruct", [("hi", [], Prelude.stringSchema)])
        let renamed = map(
            "XmlMapsXmlNameInputOutputMap",
            keyTraits: [trait(XMLNameTrait.self, "Attribute")],
            valueTraits: [trait(XMLNameTrait.self, "Setting")],
            value: greeting
        )
        let schema = structure("XmlMapsXmlNameRequest", [("myMap", [], renamed)])
        let value = TestStruct(schema) { schema, serializer in
            let valueSchema = schema.members[0].target!.value
            try serializer.writeMap(schema.members[0], ["foo": "there", "baz": "bye"]) { value, serializer in
                try serializer.writeStruct(valueSchema, TestStruct(greeting) { schema, serializer in
                    try serializer.writeString(schema.members[0], value)
                })
            }
        }

        XCTAssertEqual(try serialize(value), "<XmlMapsXmlNameRequest><myMap>" +
            "<entry><Attribute>baz</Attribute><Setting><hi>bye</hi></Setting></entry>" +
            "<entry><Attribute>foo</Attribute><Setting><hi>there</hi></Setting></entry>" +
            "</myMap></XmlMapsXmlNameRequest>")
    }

    func test_map_itWritesFlattenedMaps() throws {
        let renamed = map(
            "KVPMap",
            keyTraits: [trait(XMLNameTrait.self, "K")],
            valueTraits: [trait(XMLNameTrait.self, "V")]
        )
        let schema = structure("FlattenedXmlMapRequest", [
            ("myMap", [trait(XMLFlattenedTrait.self)], map("StringMap")),
            ("myMap2", [trait(XMLFlattenedTrait.self), trait(XMLNameTrait.self, "KVP")], renamed),
            ("empty", [trait(XMLFlattenedTrait.self)], map("StringMap")),
        ])
        let value = TestStruct(schema) { schema, serializer in
            try writeStringMap(serializer, schema.members[0], ["foo": "Foo", "baz": "Baz"])
            try writeStringMap(serializer, schema.members[1], ["a": "A", "b": "B"])
            try writeStringMap(serializer, schema.members[2], [:])
        }

        XCTAssertEqual(try serialize(value), "<FlattenedXmlMapRequest>" +
            "<myMap><key>baz</key><value>Baz</value></myMap><myMap><key>foo</key><value>Foo</value></myMap>" +
            "<KVP><K>a</K><V>A</V></KVP><KVP><K>b</K><V>B</V></KVP>" +
            "</FlattenedXmlMapRequest>")
    }

    func test_map_itWritesNestedMaps() throws {
        let inner = map("FooEnumMap")
        let outer = map("NestedMap", value: inner)
        let schema = structure("NestedXmlMapsRequest", [("nestedMap", [], outer)])
        let value = TestStruct(schema) { schema, serializer in
            let innerSchema = schema.members[0].target!.value
            try serializer.writeMap(schema.members[0], ["foo": ["bar": "Bar"]]) { value, serializer in
                try writeStringMap(serializer, innerSchema, value)
            }
        }

        XCTAssertEqual(try serialize(value), "<NestedXmlMapsRequest><nestedMap><entry><key>foo</key>" +
            "<value><entry><key>bar</key><value>Bar</value></entry></value>" +
            "</entry></nestedMap></NestedXmlMapsRequest>")
    }

    func test_map_itEscapesKeys() throws {
        let schema = structure("MapRequest", [("myMap", [], map("StringMap"))])
        let value = TestStruct(schema) { schema, serializer in
            try writeStringMap(serializer, schema.members[0], ["a&<b>": "c"])
        }

        XCTAssertEqual(try serialize(value),
            "<MapRequest><myMap><entry><key>a&amp;&lt;b&gt;</key><value>c</value></entry></myMap></MapRequest>")
    }

    // MARK: - Attributes

    func test_attributes_itWritesAttributesInTheStartTagRegardlessOfMemberOrder() throws {
        // The attribute member is after the element member, so it must be written in a separate pass.
        let schema = structure("XmlAttributesRequest", [
            ("foo", [], Prelude.stringSchema),
            ("attr", [trait(XMLAttributeTrait.self), trait(XMLNameTrait.self, "test")], Prelude.stringSchema),
        ])
        let value = TestStruct(schema) { schema, serializer in
            try serializer.writeString(schema.members[0], "hi")
            try serializer.writeString(schema.members[1], "test")
        }

        XCTAssertEqual(try serialize(value), #"<XmlAttributesRequest test="test"><foo>hi</foo></XmlAttributesRequest>"#)
    }

    func test_attributes_itEscapesAttributeValues() throws {
        let schema = structure("XmlAttributesRequest", [
            ("attr", [trait(XMLAttributeTrait.self), trait(XMLNameTrait.self, "test")], Prelude.stringSchema),
            ("foo", [], Prelude.stringSchema),
        ])
        let value = TestStruct(schema) { schema, serializer in
            try serializer.writeString(schema.members[0], "<test&mock>\"\n\t")
            try serializer.writeString(schema.members[1], "hi")
        }

        XCTAssertEqual(try serialize(value),
            #"<XmlAttributesRequest test="&lt;test&amp;mock&gt;&quot;&#xA;&#x9;"><foo>hi</foo></XmlAttributesRequest>"#)
    }

    func test_attributes_itWritesAttributesOfNestedStructuresAndNonStringAttributes() throws {
        let inner = structure("Inner", [
            ("count", [trait(XMLAttributeTrait.self)], Prelude.integerSchema),
            ("type", [trait(XMLAttributeTrait.self), trait(XMLNameTrait.self, "xsi:type")], Prelude.stringSchema),
            ("name", [], Prelude.stringSchema),
        ])
        let schema = structure("OuterRequest", [("grantee", [], inner)])
        let value = TestStruct(schema) { schema, serializer in
            try serializer.writeStruct(schema.members[0], TestStruct(inner) { schema, serializer in
                try serializer.writeInteger(schema.members[0], 3)
                try serializer.writeString(schema.members[1], "CanonicalUser")
                try serializer.writeString(schema.members[2], "n")
            })
        }

        XCTAssertEqual(try serialize(value),
            #"<OuterRequest><grantee count="3" xsi:type="CanonicalUser"><name>n</name></grantee></OuterRequest>"#)
    }

    // MARK: - Namespaces

    func test_namespaces_itWritesNamespacesPerTheXmlNamespacesTest() throws {
        let namespacedList = list(
            "XmlNamespacedList",
            memberTraits: [namespace("http://bux.com")],
            Prelude.stringSchema
        )
        let nested = structure("XmlNamespaceNested", [
            ("foo", [namespace("http://baz.com", prefix: "baz")], Prelude.stringSchema),
            ("values", [namespace("http://qux.com")], namespacedList),
        ], traits: [namespace("http://foo.com")])
        let schema = structure("XmlNamespacesRequest", [("nested", [], nested)], traits: [namespace("http://foo.com")])
        let value = TestStruct(schema) { schema, serializer in
            try serializer.writeStruct(schema.members[0], TestStruct(nested) { schema, serializer in
                try serializer.writeString(schema.members[0], "Foo")
                try writeStrings(serializer, schema.members[1], ["Bar", "Baz"])
            })
        }

        // The nested element has no namespace: a target's xmlNamespace applies only when it is the root.
        XCTAssertEqual(try serialize(value), #"<XmlNamespacesRequest xmlns="http://foo.com"><nested>"# +
            #"<foo xmlns:baz="http://baz.com">Foo</foo>"# +
            #"<values xmlns="http://qux.com"><member xmlns="http://bux.com">Bar</member>"# +
            #"<member xmlns="http://bux.com">Baz</member></values>"# +
            "</nested></XmlNamespacesRequest>")
    }

    func test_namespaces_itAppliesTheDefaultNamespaceOnlyToARootWithoutOne() throws {
        let service = try XMLNamespaceTrait(node: ["uri": "https://example.com/"])
        let plain = structure("PlainRequest", [])
        let namespaced = structure("NamespacedRequest", [], traits: [namespace("http://foo.com")])

        XCTAssertEqual(try serialize(TestStruct(plain) { _, _ in }, defaultNamespace: service),
            #"<PlainRequest xmlns="https://example.com/"></PlainRequest>"#)
        XCTAssertEqual(try serialize(TestStruct(namespaced) { _, _ in }, defaultNamespace: service),
            #"<NamespacedRequest xmlns="http://foo.com"></NamespacedRequest>"#)
    }

    // MARK: - HTTP payloads

    func test_payload_itNamesThePayloadRootByMemberThenTargetXMLName() throws {
        let payload = structure("PayloadWithXmlName", [("name", [], Prelude.stringSchema)],
                                traits: [trait(XMLNameTrait.self, "Hello")])
        let input = structure("HttpPayloadWithXmlNameRequest", [
            ("nested", [], payload),
            ("renamed", [trait(XMLNameTrait.self, "Hola")], payload),
        ])
        let body = TestStruct(payload) { schema, serializer in try serializer.writeString(schema.members[0], "Phreddy") }

        XCTAssertEqual(try serializePayload(input.members[0], body), "<Hello><name>Phreddy</name></Hello>")
        XCTAssertEqual(try serializePayload(input.members[1], body), "<Hola><name>Phreddy</name></Hola>")
    }

    func test_payload_itNamesThePayloadRootByTargetShapeNameAndUsesItsNamespace() throws {
        let payload = structure("PayloadWithXmlNamespaceAndPrefix", [("name", [], Prelude.stringSchema)],
                                traits: [namespace("http://foo.com", prefix: "baz")])
        let input = structure("HttpPayloadWithXmlNamespaceAndPrefixRequest", [("nested", [], payload)])
        let body = TestStruct(payload) { schema, serializer in try serializer.writeString(schema.members[0], "Phreddy") }

        XCTAssertEqual(try serializePayload(input.members[0], body),
            #"<PayloadWithXmlNamespaceAndPrefix xmlns:baz="http://foo.com">"# +
            "<name>Phreddy</name></PayloadWithXmlNamespaceAndPrefix>")
    }

    func test_payload_itNamesThePayloadRootForTheTargetWhenTheMemberSchemaHasTheTargetsType() throws {
        // Generated member schemas have the type of their target, not .member.
        let payload = structure("NestedPayload", [("name", [], Prelude.stringSchema)])
        let memberSchema = Schema(
            id: .init("test", "HttpPayloadWithStructureRequest", "nested"),
            type: .structure,
            containerType: .structure,
            target: payload,
            index: 0
        )
        let body = TestStruct(payload) { schema, serializer in try serializer.writeString(schema.members[0], "Phreddy") }

        XCTAssertEqual(try serializePayload(memberSchema, body), "<NestedPayload><name>Phreddy</name></NestedPayload>")
    }

    func test_payload_itWritesAttributesOnThePayloadRoot() throws {
        let payload = structure("XmlAttributesPayloadRequest", [
            ("foo", [], Prelude.stringSchema),
            ("attr", [trait(XMLAttributeTrait.self), trait(XMLNameTrait.self, "test")], Prelude.stringSchema),
        ])
        let input = structure("XmlAttributesOnPayloadRequest", [("payload", [], payload)])
        let body = TestStruct(payload) { schema, serializer in
            try serializer.writeString(schema.members[0], "hi")
            try serializer.writeString(schema.members[1], "test")
        }

        XCTAssertEqual(try serializePayload(input.members[0], body),
            #"<XmlAttributesPayloadRequest test="test"><foo>hi</foo></XmlAttributesPayloadRequest>"#)
    }

    // MARK: - Output

    func test_data_itIsNilWhenNothingWasWritten() throws {
        let subject = Serializer()

        XCTAssertNil(try subject.data)
        XCTAssertNil(subject.mediaType)
    }

    func test_mediaType_itIsXMLOnceWritten() throws {
        let subject = Serializer()
        try TestStruct(structure("R", [])) { _, _ in }.serialize(subject)

        XCTAssertEqual(subject.mediaType, "application/xml")
    }

    // MARK: - Helpers

    private func serialize(_ value: TestStruct, defaultNamespace: XMLNamespaceTrait? = nil) throws -> String {
        let serializer = Serializer(defaultNamespace: defaultNamespace)
        try value.serialize(serializer)
        return String(decoding: try serializer.data ?? Data(), as: UTF8.self)
    }

    /// Serializes a structure as an HTTP payload, the way HTTP bindings do: with the payload member's schema.
    private func serializePayload(_ memberSchema: Schema, _ value: TestStruct) throws -> String {
        let serializer = Serializer()
        try serializer.writeStruct(memberSchema, value)
        return String(decoding: try serializer.data ?? Data(), as: UTF8.self)
    }
}

// MARK: - Test model

/// A structure whose members are written by a closure, the way generated `serializeMembers` writes them.
private struct TestStruct: SerializableStruct {
    let schema: Schema
    let body: (Schema, any ShapeSerializer) throws -> Void

    init(_ schema: Schema, _ body: @escaping (Schema, any ShapeSerializer) throws -> Void) {
        self.schema = schema
        self.body = body
    }

    func serialize(_ serializer: any ShapeSerializer) throws {
        try serializer.writeStruct(schema, self)
    }

    func serializeMembers(_ schema: Schema, _ serializer: any ShapeSerializer) throws {
        try body(schema, serializer)
    }
}

private func writeStrings(_ serializer: any ShapeSerializer, _ schema: Schema, _ value: [String]) throws {
    let item = schema.target!.member
    try serializer.writeList(schema, value) { value, serializer in try serializer.writeString(item, value) }
}

private func writeStringMap(_ serializer: any ShapeSerializer, _ schema: Schema, _ value: [String: String]) throws {
    let valueSchema = schema.target!.value
    try serializer.writeMap(schema, value) { value, serializer in try serializer.writeString(valueSchema, value) }
}

private func trait<T: Trait>(_ type: T.Type, _ node: Node = [:]) -> any Trait {
    // Force-try is safe because every trait node in this file is valid
    // swiftlint:disable:next force_try
    try! T(node: node)
}

private func namespace(_ uri: String, prefix: String? = nil) -> any Trait {
    var object: [String: Node] = ["uri": .string(uri)]
    if let prefix { object["prefix"] = .string(prefix) }
    return trait(XMLNamespaceTrait.self, .object(object))
}

private func member(
    _ container: String,
    _ name: String,
    _ index: Int,
    containerType: ShapeType = .structure,
    traits: [any Trait] = [],
    _ target: @Sendable @escaping @autoclosure () -> Schema
) -> Schema {
    Schema(
        id: .init("test", container, name),
        type: .member,
        traits: TraitCollection(traits: traits),
        containerType: containerType,
        target: target(),
        index: index
    )
}

private func structure(
    _ name: String,
    _ members: [(String, [any Trait], Schema)],
    traits: [any Trait] = []
) -> Schema {
    Schema(
        id: .init("test", name),
        type: .structure,
        traits: TraitCollection(traits: traits),
        members: members.enumerated().map { index, entry in
            let target = entry.2
            return member(name, entry.0, index, traits: entry.1, target)
        }
    )
}

private func list(
    _ name: String,
    memberTraits: [any Trait] = [],
    _ target: @Sendable @escaping @autoclosure () -> Schema
) -> Schema {
    Schema(
        id: .init("test", name),
        type: .list,
        members: [member(name, "member", 0, containerType: .list, traits: memberTraits, target())]
    )
}

private func map(
    _ name: String,
    keyTraits: [any Trait] = [],
    valueTraits: [any Trait] = [],
    value: Schema = Prelude.stringSchema
) -> Schema {
    Schema(
        id: .init("test", name),
        type: .map,
        members: [
            member(name, "key", 0, containerType: .map, traits: keyTraits, Prelude.stringSchema),
            member(name, "value", 1, containerType: .map, traits: valueTraits, value),
        ]
    )
}
