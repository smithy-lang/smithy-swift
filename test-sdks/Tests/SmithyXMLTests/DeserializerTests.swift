//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(SchemaBasedSerde) import Smithy
@_spi(SchemaBasedSerde) import SmithySerialization
@_spi(SchemaBasedSerde) import SmithyXML
import XCTest

final class DeserializerTests: XCTestCase {

    // MARK: - Scalars

    func test_scalars_itReadsEveryScalarType() throws {
        let xml = """
        <TestShape>
            <string>hello</string>
            <boolean>true</boolean>
            <byte>-8</byte>
            <short>1600</short>
            <integer>-32000000</integer>
            <long>9007199254740993</long>
            <float>1.5</float>
            <double>-2.25</double>
            <bigInteger>123456789012</bigInteger>
            <bigDecimal>1.25</bigDecimal>
            <blob>dmFsdWU=</blob>
            <dateTime>2014-04-29T18:30:38Z</dateTime>
            <epochSeconds>1398796238.123</epochSeconds>
            <httpDate>Tue, 29 Apr 2014 18:30:38 GMT</httpDate>
        </TestShape>
        """
        let shape = try deserialize(xml)

        XCTAssertEqual(shape.string, "hello")
        XCTAssertEqual(shape.boolean, true)
        XCTAssertEqual(shape.byte, -8)
        XCTAssertEqual(shape.short, 1600)
        XCTAssertEqual(shape.integer, -32000000)
        XCTAssertEqual(shape.long, 9007199254740993)
        XCTAssertEqual(shape.float, 1.5)
        XCTAssertEqual(shape.double, -2.25)
        XCTAssertEqual(shape.bigInteger, 123456789012)
        XCTAssertEqual(shape.bigDecimal, 1.25)
        XCTAssertEqual(shape.blob, Data("value".utf8))
        XCTAssertEqual(shape.dateTime, Date(timeIntervalSince1970: 1398796238))
        XCTAssertEqual(shape.epochSeconds!.timeIntervalSince1970, 1398796238.123, accuracy: 0.0005)
        XCTAssertEqual(shape.httpDate, Date(timeIntervalSince1970: 1398796238))
    }

    func test_scalars_itTrimsWhitespaceAroundNonStringValues() throws {
        let shape = try deserialize("<TestShape><integer>\n  42\n</integer><boolean> false </boolean></TestShape>")

        XCTAssertEqual(shape.integer, 42)
        XCTAssertEqual(shape.boolean, false)
    }

    func test_strings_itPreservesWhitespaceInStrings() throws {
        let shape = try deserialize("<TestShape><string>  a\n b  </string></TestShape>")

        XCTAssertEqual(shape.string, "  a\n b  ")
    }

    func test_strings_itReadsEmptyElementsAsEmptyStrings() throws {
        let shape = try deserialize("<TestShape><string></string><CustomName/></TestShape>")

        XCTAssertEqual(shape.string, "")
        XCTAssertEqual(shape.renamed, "")
    }

    func test_strings_itDecodesEntitiesAndCharacterReferences() throws {
        let shape = try deserialize("<TestShape>" +
            "<string>&lt;a&gt; &amp; &quot;b&quot; &apos;c&apos; &#xA;&#65;</string>" +
            "</TestShape>")

        XCTAssertEqual(shape.string, "<a> & \"b\" 'c' \nA")
    }

    func test_strings_itReadsCDATA() throws {
        let shape = try deserialize("<TestShape><string>a<![CDATA[<b> & c]]>d</string></TestShape>")

        XCTAssertEqual(shape.string, "a<b> & cd")
    }

    func test_strings_itReadsUnicode() throws {
        let shape = try deserialize("<TestShape><string>héllo 世界 🎉</string></TestShape>")

        XCTAssertEqual(shape.string, "héllo 世界 🎉")
    }

    func test_floatingPoint_itReadsSpecialValues() throws {
        let shape = try deserialize("<TestShape><float>NaN</float><double>-Infinity</double></TestShape>")

        XCTAssertTrue(shape.float!.isNaN)
        XCTAssertEqual(shape.double, -.infinity)
        XCTAssertEqual(try deserialize("<TestShape><double>Infinity</double></TestShape>").double, .infinity)
    }

    func test_floatingPoint_itRejectsNonSmithyValues() {
        for text in ["inf", "nan", "0x1p3", "abc"] {
            XCTAssertThrowsError(try deserialize("<TestShape><double>\(text)</double></TestShape>"), text)
        }
    }

    func test_integers_itRejectsOutOfRangeAndNonIntegerValues() {
        XCTAssertThrowsError(try deserialize("<TestShape><byte>128</byte></TestShape>"))
        XCTAssertThrowsError(try deserialize("<TestShape><integer>1.5</integer></TestShape>"))
        XCTAssertThrowsError(try deserialize("<TestShape><boolean>yes</boolean></TestShape>"))
    }

    func test_blob_itIgnoresWhitespaceInBase64() throws {
        let shape = try deserialize("<TestShape><blob>\n  dmFs\n  dWU=\n</blob></TestShape>")

        XCTAssertEqual(shape.blob, Data("value".utf8))
    }

    // MARK: - Structures

    func test_struct_itUsesXMLNameForMembers() throws {
        let shape = try deserialize("<TestShape><CustomName>renamed</CustomName><renamed>ignored</renamed></TestShape>")

        XCTAssertEqual(shape.renamed, "renamed")
    }

    func test_struct_itIgnoresUnknownElementsAndNestedContent() throws {
        let xml = "<TestShape><unknown><string>no</string></unknown><string>yes</string><extra/></TestShape>"
        let shape = try deserialize(xml)

        XCTAssertEqual(shape.string, "yes")
    }

    func test_struct_itReadsNestedStructures() throws {
        let shape = try deserialize("<TestShape><nested><string>inner</string><nested><integer>2</integer>" +
            "</nested></nested></TestShape>")

        XCTAssertEqual(shape.nested?.string, "inner")
        XCTAssertEqual(shape.nested?.nested?.integer, 2)
    }

    func test_struct_itReadsAttributes() throws {
        let xml = """
        <TestShape xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" test="a &amp; b" xsi:type="CanonicalUser">
            <nested test="inner"/>
        </TestShape>
        """
        let shape = try deserialize(xml)

        XCTAssertEqual(shape.attribute, "a & b")
        XCTAssertEqual(shape.prefixedAttribute, "CanonicalUser")
        XCTAssertEqual(shape.nested?.attribute, "inner")
    }

    func test_struct_itDoesNotReadAttributeMembersFromElements() throws {
        let shape = try deserialize("<TestShape><test>element</test></TestShape>")

        XCTAssertNil(shape.attribute)
    }

    func test_struct_itPrefillsRequiredMembers() throws {
        let shape = try deserialize("<TestShape/>")

        XCTAssertEqual(shape.required, "")
        XCTAssertNil(shape.string)
    }

    func test_struct_itReadsEmptyDataAsAnEmptyStructure() throws {
        for xml in ["", "  \n "] {
            let shape = try deserialize(xml)
            XCTAssertEqual(shape.required, "")
            XCTAssertNil(shape.string)
        }
    }

    func test_struct_itIgnoresTheRootElementNameAndNamespaces() throws {
        let shape = try deserialize("<?xml version=\"1.0\"?><Anything xmlns=\"https://example.com/\">" +
            "<string>x</string></Anything>")

        XCTAssertEqual(shape.string, "x")
    }

    func test_union_itReadsTheMemberThatIsPresent() throws {
        let shape = try deserialize("<TestShape><union><integer>7</integer></union></TestShape>")

        XCTAssertEqual(shape.union, .integer(7))
    }

    // MARK: - Lists

    func test_list_itReadsWrappedListsWithMemberElements() throws {
        let shape = try deserialize("<TestShape><list><member>a</member><member>b</member><other>x</other>" +
            "</list></TestShape>")

        XCTAssertEqual(shape.list, ["a", "b"])
    }

    func test_list_itReadsListsWithRenamedMembers() throws {
        let shape = try deserialize("<TestShape><renamedList><item>a</item><member>no</member>" +
            "<item>b</item></renamedList></TestShape>")

        XCTAssertEqual(shape.renamedList, ["a", "b"])
    }

    func test_list_itReadsEmptyLists() throws {
        let shape = try deserialize("<TestShape><list/></TestShape>")

        XCTAssertEqual(shape.list, [])
    }

    func test_list_itReadsFlattenedListsThatAreNotContiguous() throws {
        let xml = "<TestShape><flatItem>a</flatItem><string>x</string>" +
            "<flatItem>b</flatItem><flatItem>c</flatItem></TestShape>"
        let shape = try deserialize(xml)

        XCTAssertEqual(shape.flattenedList, ["a", "b", "c"])
        XCTAssertEqual(shape.string, "x")
    }

    func test_list_itReadsNestedLists() throws {
        let xml = """
        <TestShape><nestedList>
            <member><member>a</member><member>b</member></member>
            <member><member>c</member></member>
        </nestedList></TestShape>
        """
        let shape = try deserialize(xml)

        XCTAssertEqual(shape.nestedList, [["a", "b"], ["c"]])
    }

    func test_list_itReadsListsOfStructures() throws {
        let xml = "<TestShape><structList><member><string>a</string></member><member>" +
            "<integer>1</integer></member></structList></TestShape>"
        let shape = try deserialize(xml)

        XCTAssertEqual(shape.structList?.map(\.string), ["a", nil])
        XCTAssertEqual(shape.structList?.map(\.integer), [nil, 1])
    }

    // MARK: - Maps

    func test_map_itReadsWrappedMaps() throws {
        let xml = """
        <TestShape><map>
            <entry><key>a</key><value>1</value></entry>
            <entry><value>2</value><key>b</key></entry>
        </map></TestShape>
        """
        let shape = try deserialize(xml)

        XCTAssertEqual(shape.map, ["a": "1", "b": "2"])
    }

    func test_map_itReadsMapsWithRenamedKeysAndValues() throws {
        let shape = try deserialize("<TestShape><renamedMap><entry><K>a</K><V>1</V></entry></renamedMap></TestShape>")

        XCTAssertEqual(shape.renamedMap, ["a": "1"])
    }

    func test_map_itReadsFlattenedMaps() throws {
        let xml = """
        <TestShape>
            <flatMap><key>a</key><value>1</value></flatMap>
            <string>x</string>
            <flatMap><key>b</key><value>2</value></flatMap>
        </TestShape>
        """
        let shape = try deserialize(xml)

        XCTAssertEqual(shape.flattenedMap, ["a": "1", "b": "2"])
    }

    func test_map_itReadsEmptyValuesAndSkipsIncompleteEntries() throws {
        let xml = "<TestShape><map><entry><key>a</key><value/></entry><entry><key>b</key></entry></map></TestShape>"
        let shape = try deserialize(xml)

        XCTAssertEqual(shape.map, ["a": ""])
    }

    // MARK: - Protocol wrappers

    func test_awsQuery_itReadsTheResultInsideTheResponseWrapper() throws {
        let xml = """
        <GetThingResponse xmlns="https://example.com/doc/2010-05-08/">
            <GetThingResult><string>result</string></GetThingResult>
            <ResponseMetadata><RequestId>abc</RequestId></ResponseMetadata>
        </GetThingResponse>
        """
        let subject = try Deserializer(data: Data(xml.utf8))
        XCTAssertEqual(subject.elementName, "GetThingResponse")

        var shape = TestShape()
        try subject.child(named: "GetThingResult").readStruct(TestShape.schema, &shape)

        XCTAssertEqual(shape.string, "result")
    }

    func test_awsQuery_itReadsAMissingResultAsAnEmptyStructure() throws {
        let subject = try Deserializer(data: Data("<GetThingResponse><ResponseMetadata/></GetThingResponse>".utf8))

        var shape = TestShape()
        try subject.child(named: "GetThingResult").readStruct(TestShape.schema, &shape)

        XCTAssertEqual(shape.required, "")
    }

    func test_errors_itReadsAWSQueryAndRestXMLErrors() throws {
        let xml = """
        <ErrorResponse>
            <Error><Type>Sender</Type><Code>InvalidThing</Code><Message>Bad thing</Message></Error>
            <RequestId>abc</RequestId>
        </ErrorResponse>
        """
        let subject = try Deserializer(data: Data(xml.utf8))

        var error = ErrorShape()
        try subject.child(named: "Error").readStruct(ErrorShape.schema, &error)

        XCTAssertEqual(error.code, "InvalidThing")
        XCTAssertEqual(error.message, "Bad thing")
    }

    func test_errors_itReadsEC2QueryErrors() throws {
        let xml = """
        <Response>
            <Errors><Error><Code>InvalidThing</Code><Message>Bad thing</Message></Error></Errors>
            <RequestID>abc</RequestID>
        </Response>
        """
        let subject = try Deserializer(data: Data(xml.utf8))

        var error = ErrorShape()
        try subject.child(named: "Errors").child(named: "Error").readStruct(ErrorShape.schema, &error)

        XCTAssertEqual(error.code, "InvalidThing")
        XCTAssertEqual(error.message, "Bad thing")
    }

    // MARK: - Invalid & hostile XML

    func test_invalidXML_itThrowsForMalformedXML() {
        for xml in ["<TestShape>", "<a></b>", "not xml", "<a><b></a>", "<TestShape/><extra/>", "<TestShape/>junk"] {
            XCTAssertThrowsError(try deserialize(xml), xml)
        }
    }

    func test_invalidXML_itRejectsDocumentTypeDeclarations() {
        let xml = """
        <?xml version="1.0"?>
        <!DOCTYPE lolz [<!ENTITY lol "lol"><!ENTITY lol2 "&lol;&lol;&lol;&lol;">]>
        <TestShape><string>&lol2;</string></TestShape>
        """
        XCTAssertThrowsError(try deserialize(xml))
    }

    func test_invalidXML_itRejectsExternalEntities() {
        let xml = """
        <?xml version="1.0"?>
        <!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
        <TestShape><string>&xxe;</string></TestShape>
        """
        XCTAssertThrowsError(try deserialize(xml))
    }

    func test_invalidXML_itRejectsUndefinedEntities() {
        XCTAssertThrowsError(try deserialize("<TestShape><string>&undefined;</string></TestShape>"))
    }

    func test_depth_itRejectsDocumentsNestedTooDeeply() {
        let depth = 300
        let xml = String(repeating: "<a>", count: depth) + String(repeating: "</a>", count: depth)
        XCTAssertThrowsError(try deserialize(xml))
    }

    func test_depth_itAcceptsDeeplyNestedStructuresWithinTheLimit() throws {
        let depth = 100
        let xml = "<TestShape>" + String(repeating: "<nested>", count: depth) + "<integer>1</integer>" +
            String(repeating: "</nested>", count: depth) + "</TestShape>"
        var nested = try deserialize(xml).nested
        for _ in 1..<depth { nested = nested?.nested }

        XCTAssertEqual(nested?.integer, 1)
    }

    func test_documents_itThrowsForDocuments() throws {
        let subject = try Deserializer(data: Data("<a/>".utf8))

        XCTAssertThrowsError(try subject.readDocument(Prelude.documentSchema))
    }

    // MARK: - Streaming

    func test_streaming_itReadsDocumentsLargerThanOneChunk() throws {
        // Long strings & many items, so values & elements straddle the boundaries between parsed chunks.
        let longString = String(repeating: "abcdefghij", count: 5_000)
        let items = (0..<2_000).map { "item\($0)" }
        // Built in steps; one long concatenation is too slow for some compilers to type-check.
        let flatItems = items.map { "<flatItem>\($0)</flatItem>" }.joined()
        let mapEntries = items.map { "<entry><key>\($0)</key><value>\($0)</value></entry>" }.joined()
        var xml = "<TestShape><string>\(longString)</string>"
        xml += flatItems
        xml += "<map>\(mapEntries)</map>"
        xml += "<integer>5</integer></TestShape>"
        XCTAssertGreaterThan(xml.utf8.count, 100_000)

        let shape = try deserialize(xml)

        XCTAssertEqual(shape.string, longString)
        XCTAssertEqual(shape.flattenedList, items)
        XCTAssertEqual(shape.map?.count, items.count)
        XCTAssertEqual(shape.map?["item1999"], "item1999")
        XCTAssertEqual(shape.integer, 5)
    }

    func test_streaming_itSkipsMembersThatAreNotRead() throws {
        // `unread` is a member of the schema that TestShape.deserializeMember doesn't read.
        let xml = "<TestShape><unread><string>no</string><nested/></unread><string>yes</string></TestShape>"
        let shape = try deserialize(xml)

        XCTAssertEqual(shape.string, "yes")
    }

    func test_streaming_itReadsTheRestOfTheDocumentAfterTheRootElement() throws {
        let shape = try deserialize("<TestShape><string>x</string></TestShape>\n<!-- trailing comment -->\n")

        XCTAssertEqual(shape.string, "x")
    }

    func test_flattened_itCombinesNonAdjacentRunsOfAFlattenedMap() throws {
        let xml = "<TestShape><flatMap><key>a</key><value>1</value></flatMap><string>x</string>" +
            "<flatMap><key>b</key><value>2</value></flatMap><flatMap><key>a</key><value>3</value></flatMap></TestShape>"
        let shape = try deserialize(xml)

        XCTAssertEqual(shape.flattenedMap, ["a": "3", "b": "2"])
    }

    // MARK: - Helpers

    private func deserialize(_ xml: String) throws -> TestShape {
        try TestShape.deserialize(Deserializer(data: Data(xml.utf8)))
    }
}

// MARK: - Test model

private func trait<T: Trait>(_ type: T.Type, _ node: Node = [:]) -> any Trait {
    // Force-try is safe because every trait node in this file is valid
    // swiftlint:disable:next force_try
    try! T(node: node)
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

private func listSchema(
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

private func mapSchema(_ name: String, keyTraits: [any Trait] = [], valueTraits: [any Trait] = []) -> Schema {
    Schema(
        id: .init("test", name),
        type: .map,
        members: [
            member(name, "key", 0, containerType: .map, traits: keyTraits, Prelude.stringSchema),
            member(name, "value", 1, containerType: .map, traits: valueTraits, Prelude.stringSchema),
        ]
    )
}

private enum Schemas {
    static let stringList = listSchema("StringList", Prelude.stringSchema)
    static let itemList = listSchema("ItemList", memberTraits: [trait(XMLNameTrait.self, "item")], Prelude.stringSchema)
    static let nestedList = listSchema("NestedList", stringList)
    static let structList = listSchema("StructList", TestShape.schema)
    static let stringMap = mapSchema("StringMap")
    static let renamedMap = mapSchema(
        "RenamedMap", keyTraits: [trait(XMLNameTrait.self, "K")], valueTraits: [trait(XMLNameTrait.self, "V")]
    )
    static let epochSeconds = Schema(
        id: .init("test", "EpochSeconds"),
        type: .timestamp,
        traits: TraitCollection(traits: [trait(TimestampFormatTrait.self, "epoch-seconds")])
    )
    static let httpDate = Schema(
        id: .init("test", "HttpDate"),
        type: .timestamp,
        traits: TraitCollection(traits: [trait(TimestampFormatTrait.self, "http-date")])
    )
    static let union = Schema(
        id: .init("test", "TestUnion"),
        type: .union,
        members: [
            member("TestUnion", "string", 0, containerType: .union, Prelude.stringSchema),
            member("TestUnion", "integer", 1, containerType: .union, Prelude.integerSchema),
        ]
    )
}

private struct TestShape: DeserializableStruct {
    var string: String?
    var boolean: Bool?
    var byte: Int8?
    var short: Int16?
    var integer: Int32?
    var long: Int64?
    var float: Float?
    var double: Double?
    var bigInteger: Int64?
    var bigDecimal: Double?
    var blob: Data?
    var dateTime: Date?
    var epochSeconds: Date?
    var httpDate: Date?
    var renamed: String?
    var attribute: String?
    var prefixedAttribute: String?
    var list: [String]?
    var renamedList: [String]?
    var flattenedList: [String]?
    var nestedList: [[String]]?
    var structList: [TestShape]?
    var map: [String: String]?
    var renamedMap: [String: String]?
    var flattenedMap: [String: String]?
    var nested: Box?
    var union: TestUnion?
    var required: String?

    /// Breaks the recursion of `TestShape` containing itself.
    final class Box: Sendable {
        let value: TestShape
        init(_ value: TestShape) { self.value = value }
    }

    static let schema: Schema = {
        let name = "TestShape"
        let members: [(String, [any Trait], @Sendable () -> Schema)] = [
            ("string", [], { Prelude.stringSchema }),
            ("boolean", [], { Prelude.booleanSchema }),
            ("byte", [], { Prelude.byteSchema }),
            ("short", [], { Prelude.shortSchema }),
            ("integer", [], { Prelude.integerSchema }),
            ("long", [], { Prelude.longSchema }),
            ("float", [], { Prelude.floatSchema }),
            ("double", [], { Prelude.doubleSchema }),
            ("bigInteger", [], { Prelude.bigIntegerSchema }),
            ("bigDecimal", [], { Prelude.bigDecimalSchema }),
            ("blob", [], { Prelude.blobSchema }),
            ("dateTime", [], { Prelude.timestampSchema }),
            ("epochSeconds", [trait(TimestampFormatTrait.self, "epoch-seconds")], { Schemas.epochSeconds }),
            ("httpDate", [trait(TimestampFormatTrait.self, "http-date")], { Schemas.httpDate }),
            ("renamed", [trait(XMLNameTrait.self, "CustomName")], { Prelude.stringSchema }),
            ("attribute", [trait(XMLAttributeTrait.self), trait(XMLNameTrait.self, "test")], { Prelude.stringSchema }),
            (
                "prefixedAttribute",
                [trait(XMLAttributeTrait.self), trait(XMLNameTrait.self, "xsi:type")],
                { Prelude.stringSchema }
            ),
            ("list", [], { Schemas.stringList }),
            ("renamedList", [], { Schemas.itemList }),
            (
                "flattenedList",
                [trait(XMLFlattenedTrait.self), trait(XMLNameTrait.self, "flatItem")],
                { Schemas.stringList }
            ),
            ("nestedList", [], { Schemas.nestedList }),
            ("structList", [], { Schemas.structList }),
            ("map", [], { Schemas.stringMap }),
            ("renamedMap", [], { Schemas.renamedMap }),
            (
                "flattenedMap",
                [trait(XMLFlattenedTrait.self), trait(XMLNameTrait.self, "flatMap")],
                { Schemas.stringMap }
            ),
            ("nested", [], { TestShape.schema }),
            ("union", [], { Schemas.union }),
            ("required", [trait(RequiredTrait.self)], { Prelude.stringSchema }),
            ("unread", [], { TestShape.schema }),
        ]
        return Schema(
            id: .init("test", name),
            type: .structure,
            members: members.enumerated().map { index, entry in
                member(name, entry.0, index, traits: entry.1, entry.2())
            }
        )
    }()

    static func deserialize(_ deserializer: any ShapeDeserializer) throws -> TestShape {
        var value = TestShape()
        try deserializer.readStruct(schema, &value)
        return value
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    mutating func deserializeMember(_ memberSchema: Schema, _ deserializer: any ShapeDeserializer) throws {
        switch memberSchema.index {
        case 0: string = try deserializer.readString(memberSchema)
        case 1: boolean = try deserializer.readBoolean(memberSchema)
        case 2: byte = try deserializer.readByte(memberSchema)
        case 3: short = try deserializer.readShort(memberSchema)
        case 4: integer = try deserializer.readInteger(memberSchema)
        case 5: long = try deserializer.readLong(memberSchema)
        case 6: float = try deserializer.readFloat(memberSchema)
        case 7: double = try deserializer.readDouble(memberSchema)
        case 8: bigInteger = try deserializer.readBigInteger(memberSchema)
        case 9: bigDecimal = try deserializer.readBigDecimal(memberSchema)
        case 10: blob = try deserializer.readBlob(memberSchema)
        case 11, 12, 13:
            let date = try deserializer.readTimestamp(memberSchema)
            switch memberSchema.index {
            case 11: dateTime = date
            case 12: epochSeconds = date
            default: httpDate = date
            }
        case 14: renamed = try deserializer.readString(memberSchema)
        case 15: attribute = try deserializer.readString(memberSchema)
        case 16: prefixedAttribute = try deserializer.readString(memberSchema)
        case 17, 18, 19:
            let itemSchema = memberSchema.target!.member
            let value = try deserializer.readList(memberSchema) { try $0.readString(itemSchema) }
            switch memberSchema.index {
            case 17: list = value
            case 18: renamedList = value
            default: flattenedList = value
            }
        case 20:
            let innerListSchema = memberSchema.target!.member
            nestedList = try deserializer.readList(memberSchema) { deserializer in
                let itemSchema = innerListSchema.target!.member
                return try deserializer.readList(innerListSchema) { try $0.readString(itemSchema) }
            }
        case 21:
            let itemSchema = memberSchema.target!.member
            structList = try deserializer.readList(memberSchema) { deserializer in
                var value = TestShape()
                try deserializer.readStruct(itemSchema, &value)
                return value
            }
        case 22, 23, 24:
            let valueSchema = memberSchema.target!.value
            let value = try deserializer.readMap(memberSchema) { try $0.readString(valueSchema) }
            switch memberSchema.index {
            case 22: map = value
            case 23: renamedMap = value
            default: flattenedMap = value
            }
        case 25:
            var value = TestShape()
            try deserializer.readStruct(memberSchema, &value)
            nested = Box(value)
        case 26:
            var value = TestUnion.sdkUnknown("")
            try deserializer.readStruct(memberSchema, &value)
            union = value
        case 27: required = try deserializer.readString(memberSchema)
        default: break
        }
    }
}

fileprivate extension TestShape.Box {
    var string: String? { value.string }
    var integer: Int32? { value.integer }
    var attribute: String? { value.attribute }
    var nested: TestShape.Box? { value.nested }
}

private enum TestUnion: DeserializableStruct, Equatable {
    case string(String)
    case integer(Int32)
    case sdkUnknown(String)

    static func deserialize(_ deserializer: any ShapeDeserializer) throws -> TestUnion {
        var value = TestUnion.sdkUnknown("")
        try deserializer.readStruct(Schemas.union, &value)
        return value
    }

    mutating func deserializeMember(_ memberSchema: Schema, _ deserializer: any ShapeDeserializer) throws {
        switch memberSchema.index {
        case 0: self = .string(try deserializer.readString(memberSchema))
        case 1: self = .integer(try deserializer.readInteger(memberSchema))
        default: break
        }
    }
}

private struct ErrorShape: DeserializableStruct {
    var code: String?
    var message: String?

    static let schema = Schema(
        id: .init("test", "ErrorShape"),
        type: .structure,
        members: [
            member("ErrorShape", "code", 0, traits: [trait(XMLNameTrait.self, "Code")], Prelude.stringSchema),
            member("ErrorShape", "message", 1, traits: [trait(XMLNameTrait.self, "Message")], Prelude.stringSchema),
        ]
    )

    static func deserialize(_ deserializer: any ShapeDeserializer) throws -> ErrorShape {
        var value = ErrorShape()
        try deserializer.readStruct(schema, &value)
        return value
    }

    mutating func deserializeMember(_ memberSchema: Schema, _ deserializer: any ShapeDeserializer) throws {
        switch memberSchema.index {
        case 0: code = try deserializer.readString(memberSchema)
        case 1: message = try deserializer.readString(memberSchema)
        default: break
        }
    }
}
