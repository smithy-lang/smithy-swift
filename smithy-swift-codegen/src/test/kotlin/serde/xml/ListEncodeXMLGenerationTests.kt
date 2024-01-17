/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class ListEncodeXMLGenerationTests {
    @Test
    fun `001 wrapped list with xmlName`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListXmlNameInput+Encodable.swift")
        val expectedContents = """
extension XmlListXmlNameInput {
    static func writingClosure(_ value: XmlListXmlNameInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["renamed"].writeList(value.renamedListMembers, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: "item", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 nested wrapped list with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListXmlNameNestedInput+Encodable.swift")
        val expectedContents = """
extension XmlListXmlNameNestedInput {
    static func writingClosure(_ value: XmlListXmlNameNestedInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["renamed"].writeList(value.renamedListMembers, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: "subItem", isFlattened: false), memberNodeInfo: "item", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 nested wrapped list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nested-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedWrappedListInput+Encodable.swift")
        val expectedContents = """
extension XmlNestedWrappedListInput {
    static func writingClosure(_ value: XmlNestedWrappedListInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["nestedStringList"].writeList(value.nestedStringList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 nestednested wrapped list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedNestedWrappedListInput+Encodable.swift")
        val expectedContents = """
extension XmlNestedNestedWrappedListInput {
    static func writingClosure(_ value: XmlNestedNestedWrappedListInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["nestedNestedStringList"].writeList(value.nestedNestedStringList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 nestednested flattened list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedNestedFlattenedListInput+Encodable.swift")
        val expectedContents = """
extension XmlNestedNestedFlattenedListInput {
    static func writingClosure(_ value: XmlNestedNestedFlattenedListInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["nestedNestedStringList"].writeList(value.nestedNestedStringList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `006 empty lists`() {
        val context = setupTests("Isolated/Restxml/xml-lists-empty.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEmptyListsInput+Encodable.swift")
        val expectedContents = """
extension XmlEmptyListsInput {
    static func writingClosure(_ value: XmlEmptyListsInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["booleanList"].writeList(value.booleanList, memberWritingClosure: Swift.Bool.writingClosure(_:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["integerList"].writeList(value.integerList, memberWritingClosure: Swift.Int.writingClosure(_:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["stringList"].writeList(value.stringList, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["stringSet"].writeList(value.stringSet, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `007 wrapped list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlWrappedListInput+Encodable.swift")
        val expectedContents = """
extension XmlWrappedListInput {
    static func writingClosure(_ value: XmlWrappedListInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["myGroceryList"].writeList(value.myGroceryList, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `008 flattened list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlFlattenedListInput+Encodable.swift")
        val expectedContents = """
extension XmlFlattenedListInput {
    static func writingClosure(_ value: XmlFlattenedListInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["myGroceryList"].writeList(value.myGroceryList, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: "member", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `010 encode nested flattened datetime encodable`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened-nested-datetime.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsNestedFlattenedInput+Encodable.swift")
        val expectedContents = """
extension XmlTimestampsNestedFlattenedInput {
    static func writingClosure(_ value: XmlTimestampsNestedFlattenedInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["nestedTimestampList"].writeList(value.nestedTimestampList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: SmithyXML.timestampWritingClosure(format: .epochSeconds), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: .init("nestedMember", namespaceDef: .init(prefix: "baz", uri: "http://baz.com")), isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `011 encode flattened empty list`() {
        val context = setupTests("Isolated/Restxml/xml-lists-emptyFlattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEmptyFlattenedListsInput+Encodable.swift")
        val expectedContents = """
extension XmlEmptyFlattenedListsInput {
    static func writingClosure(_ value: XmlEmptyFlattenedListsInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["booleanList"].writeList(value.booleanList, memberWritingClosure: Swift.Bool.writingClosure(_:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["integerList"].writeList(value.integerList, memberWritingClosure: Swift.Int.writingClosure(_:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["stringList"].writeList(value.stringList, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: "member", isFlattened: true)
        try writer["stringSet"].writeList(value.stringSet, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: "member", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `011 encode list flattened nested with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened-nested-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListNestedFlattenedXmlNameInput+Encodable.swift")
        val expectedContents = """
extension XmlListNestedFlattenedXmlNameInput {
    static func writingClosure(_ value: XmlListNestedFlattenedXmlNameInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["listOfNestedStrings"].writeList(value.nestedList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: "nestedNestedMember", isFlattened: false), memberNodeInfo: "nestedMember", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `012 encode list containing map`() {
        val context = setupTests("Isolated/Restxml/xml-lists-contain-map.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListContainMapInput+Encodable.swift")
        val expectedContents = """
extension XmlListContainMapInput {
    static func writingClosure(_ value: XmlListContainMapInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["myList"].writeList(value.myList, memberWritingClosure: SmithyXML.mapWritingClosure(valueWritingClosure: Swift.String.writingClosure(_:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `013 encode flattened list containing map`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened-contain-map.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListFlattenedContainMapInput+Encodable.swift")
        val expectedContents = """
extension XmlListFlattenedContainMapInput {
    static func writingClosure(_ value: XmlListFlattenedContainMapInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["myList"].writeList(value.myList, memberWritingClosure: SmithyXML.mapWritingClosure(valueWritingClosure: Swift.String.writingClosure(_:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), memberNodeInfo: "member", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
