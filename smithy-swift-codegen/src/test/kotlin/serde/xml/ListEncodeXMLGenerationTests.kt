/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package serde.xml

import MockHTTPRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class ListEncodeXMLGenerationTests {
    @Test
    fun `001 wrapped list with xmlName`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlListXmlNameInput+Write.swift")
        val expectedContents = """
extension XmlListXmlNameInput {

    static func write(value: XmlListXmlNameInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["renamed"].writeList(value.renamedListMembers, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "item", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 nested wrapped list with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlListXmlNameNestedInput+Write.swift")
        val expectedContents = """
extension XmlListXmlNameNestedInput {

    static func write(value: XmlListXmlNameNestedInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["renamed"].writeList(value.renamedListMembers, memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "subItem", isFlattened: false), memberNodeInfo: "item", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 nested wrapped list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nested-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlNestedWrappedListInput+Write.swift")
        val expectedContents = """
extension XmlNestedWrappedListInput {

    static func write(value: XmlNestedWrappedListInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["nestedStringList"].writeList(value.nestedStringList, memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 nestednested wrapped list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlNestedNestedWrappedListInput+Write.swift")
        val expectedContents = """
extension XmlNestedNestedWrappedListInput {

    static func write(value: XmlNestedNestedWrappedListInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["nestedNestedStringList"].writeList(value.nestedNestedStringList, memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 nestednested flattened list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlNestedNestedFlattenedListInput+Write.swift")
        val expectedContents = """
extension XmlNestedNestedFlattenedListInput {

    static func write(value: XmlNestedNestedFlattenedListInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["nestedNestedStringList"].writeList(value.nestedNestedStringList, memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `006 empty lists`() {
        val context = setupTests("Isolated/Restxml/xml-lists-empty.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlEmptyListsInput+Write.swift")
        val expectedContents = """
extension XmlEmptyListsInput {

    static func write(value: XmlEmptyListsInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["booleanList"].writeList(value.booleanList, memberWritingClosure: SmithyReadWrite.WritingClosures.writeBool(value:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["integerList"].writeList(value.integerList, memberWritingClosure: SmithyReadWrite.WritingClosures.writeInt(value:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["stringList"].writeList(value.stringList, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["stringSet"].writeList(value.stringSet, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `007 wrapped list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlWrappedListInput+Write.swift")
        val expectedContents = """
extension XmlWrappedListInput {

    static func write(value: XmlWrappedListInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["myGroceryList"].writeList(value.myGroceryList, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `008 flattened list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlFlattenedListInput+Write.swift")
        val expectedContents = """
extension XmlFlattenedListInput {

    static func write(value: XmlFlattenedListInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["myGroceryList"].writeList(value.myGroceryList, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `010 encode nested flattened datetime encodable`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened-nested-datetime.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlTimestampsNestedFlattenedInput+Write.swift")
        val expectedContents = """
extension XmlTimestampsNestedFlattenedInput {

    static func write(value: XmlTimestampsNestedFlattenedInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["nestedTimestampList"].writeList(value.nestedTimestampList, memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.timestampWritingClosure(format: .epochSeconds), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: .init("nestedMember", namespaceDef: .init(prefix: "baz", uri: "http://baz.com")), isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `011 encode flattened empty list`() {
        val context = setupTests("Isolated/Restxml/xml-lists-emptyFlattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlEmptyFlattenedListsInput+Write.swift")
        val expectedContents = """
extension XmlEmptyFlattenedListsInput {

    static func write(value: XmlEmptyFlattenedListsInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["booleanList"].writeList(value.booleanList, memberWritingClosure: SmithyReadWrite.WritingClosures.writeBool(value:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["integerList"].writeList(value.integerList, memberWritingClosure: SmithyReadWrite.WritingClosures.writeInt(value:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["stringList"].writeList(value.stringList, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: true)
        try writer["stringSet"].writeList(value.stringSet, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `011 encode list flattened nested with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened-nested-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlListNestedFlattenedXmlNameInput+Write.swift")
        val expectedContents = """
extension XmlListNestedFlattenedXmlNameInput {

    static func write(value: XmlListNestedFlattenedXmlNameInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["listOfNestedStrings"].writeList(value.nestedList, memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "nestedNestedMember", isFlattened: false), memberNodeInfo: "nestedMember", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `012 encode list containing map`() {
        val context = setupTests("Isolated/Restxml/xml-lists-contain-map.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlListContainMapInput+Write.swift")
        val expectedContents = """
extension XmlListContainMapInput {

    static func write(value: XmlListContainMapInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["myList"].writeList(value.myList, memberWritingClosure: SmithyReadWrite.mapWritingClosure(valueWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `013 encode flattened list containing map`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened-contain-map.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlListFlattenedContainMapInput+Write.swift")
        val expectedContents = """
extension XmlListFlattenedContainMapInput {

    static func write(value: XmlListFlattenedContainMapInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["myList"].writeList(value.myList, memberWritingClosure: SmithyReadWrite.mapWritingClosure(valueWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), memberNodeInfo: "member", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHTTPRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
