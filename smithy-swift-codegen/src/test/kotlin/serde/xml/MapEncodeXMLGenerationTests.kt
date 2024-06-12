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

class MapEncodeXMLGenerationTests {
    @Test
    fun `001 encode map`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsInput+Write.swift")
        val expectedContents = """
extension XmlMapsInput {

    static func write(value: XmlMapsInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["myMap"].writeMap(value.myMap, valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 encode map with name protocol`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsWithNameProtocolInput+Write.swift")
        val expectedContents = """
extension XmlMapsWithNameProtocolInput {

    static func write(value: XmlMapsWithNameProtocolInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["protocol"].writeMap(value.`protocol`, valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 encode nested wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsNestedInput+Write.swift")
        val expectedContents = """
extension XmlMapsNestedInput {

    static func write(value: XmlMapsNestedInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["myMap"].writeMap(value.myMap, valueWritingClosure: SmithyReadWrite.mapWritingClosure(valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 encode nested nested wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nestednested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsNestedNestedInput+Write.swift")
        val expectedContents = """
extension XmlMapsNestedNestedInput {

    static func write(value: XmlMapsNestedNestedInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["myMap"].writeMap(value.myMap, valueWritingClosure: SmithyReadWrite.mapWritingClosure(valueWritingClosure: SmithyReadWrite.mapWritingClosure(valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 encode flattened map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlFlattenedMapsInput+Write.swift")
        val expectedContents = """
extension XmlFlattenedMapsInput {

    static func write(value: XmlFlattenedMapsInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["myMap"].writeMap(value.myMap, valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `006 encode flattened nested map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsFlattenedNestedInput+Write.swift")
        val expectedContents = """
extension XmlMapsFlattenedNestedInput {

    static func write(value: XmlMapsFlattenedNestedInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["myMap"].writeMap(value.myMap, valueWritingClosure: SmithyReadWrite.mapWritingClosure(valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `007 encode map with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsXmlNameInput+Write.swift")
        val expectedContents = """
extension XmlMapsXmlNameInput {

    static func write(value: XmlMapsXmlNameInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["myMap"].writeMap(value.myMap, valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.write(value:to:), keyNodeInfo: "Attribute", valueNodeInfo: "Setting", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `008 encode map with xmlname flattened`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsXmlNameFlattenedInput+Write.swift")
        val expectedContents = """
extension XmlMapsXmlNameFlattenedInput {

    static func write(value: XmlMapsXmlNameFlattenedInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["myMap"].writeMap(value.myMap, valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.write(value:to:), keyNodeInfo: "SomeCustomKey", valueNodeInfo: "SomeCustomValue", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `009 encode map with xmlname nested`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsXmlNameNestedInput+Write.swift")
        val expectedContents = """
extension XmlMapsXmlNameNestedInput {

    static func write(value: XmlMapsXmlNameNestedInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["myMap"].writeMap(value.myMap, valueWritingClosure: SmithyReadWrite.mapWritingClosure(valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.write(value:to:), keyNodeInfo: "CustomKey2", valueNodeInfo: "CustomValue2", isFlattened: false), keyNodeInfo: "CustomKey1", valueNodeInfo: "CustomValue1", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `010 encode flattened nested map with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsFlattenedNestedXmlNameInput+Write.swift")
        val expectedContents = """
extension XmlMapsFlattenedNestedXmlNameInput {

    static func write(value: XmlMapsFlattenedNestedXmlNameInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["myMap"].writeMap(value.myMap, valueWritingClosure: SmithyReadWrite.mapWritingClosure(valueWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), keyNodeInfo: "K", valueNodeInfo: "V", isFlattened: false), keyNodeInfo: "yek", valueNodeInfo: "eulav", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `011 encode map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsXmlNamespaceInput+Write.swift")
        val expectedContents = """
extension XmlMapsXmlNamespaceInput {

    static func write(value: XmlMapsXmlNamespaceInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer[.init("myMap", namespaceDef: .init(prefix: "", uri: "http://boo.com"))].writeMap(value.myMap, valueWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), keyNodeInfo: .init("Quality", namespaceDef: .init(prefix: "", uri: "http://doo.com")), valueNodeInfo: .init("Degree", namespaceDef: .init(prefix: "", uri: "http://eoo.com")), isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `012 encode flattened map xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsFlattenedXmlNamespaceInput+Write.swift")
        val expectedContents = """
extension XmlMapsFlattenedXmlNamespaceInput {

    static func write(value: XmlMapsFlattenedXmlNamespaceInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer[.init("myMap", namespaceDef: .init(prefix: "", uri: "http://boo.com"))].writeMap(value.myMap, valueWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), keyNodeInfo: .init("Uid", namespaceDef: .init(prefix: "", uri: "http://doo.com")), valueNodeInfo: .init("Val", namespaceDef: .init(prefix: "", uri: "http://eoo.com")), isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `013 encode nested map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nested-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsNestedXmlNamespaceInput+Write.swift")
        val expectedContents = """
extension XmlMapsNestedXmlNamespaceInput {

    static func write(value: XmlMapsNestedXmlNamespaceInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer[.init("myMap", namespaceDef: .init(prefix: "", uri: "http://boo.com"))].writeMap(value.myMap, valueWritingClosure: SmithyReadWrite.mapWritingClosure(valueWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), keyNodeInfo: .init("K", namespaceDef: .init(prefix: "", uri: "http://goo.com")), valueNodeInfo: .init("V", namespaceDef: .init(prefix: "", uri: "http://hoo.com")), isFlattened: false), keyNodeInfo: .init("yek", namespaceDef: .init(prefix: "", uri: "http://doo.com")), valueNodeInfo: .init("eulav", namespaceDef: .init(prefix: "", uri: "http://eoo.com")), isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `014 encode nested flattened map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsFlattenedNestedXmlNamespaceInput+Write.swift")
        val expectedContents = """
extension XmlMapsFlattenedNestedXmlNamespaceInput {

    static func write(value: XmlMapsFlattenedNestedXmlNamespaceInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer[.init("myMap", namespaceDef: .init(prefix: "", uri: "http://boo.com"))].writeMap(value.myMap, valueWritingClosure: SmithyReadWrite.mapWritingClosure(valueWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), keyNodeInfo: .init("K", namespaceDef: .init(prefix: "", uri: "http://goo.com")), valueNodeInfo: .init("V", namespaceDef: .init(prefix: "", uri: "http://hoo.com")), isFlattened: false), keyNodeInfo: .init("yek", namespaceDef: .init(prefix: "", uri: "http://doo.com")), valueNodeInfo: .init("eulav", namespaceDef: .init(prefix: "", uri: "http://eoo.com")), isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `015 encode map containing list`() {
        val context = setupTests("Isolated/Restxml/xml-maps-contain-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsContainListInput+Write.swift")
        val expectedContents = """
extension XmlMapsContainListInput {

    static func write(value: XmlMapsContainListInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["myMap"].writeMap(value.myMap, valueWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `016 encode flattened map containing list`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-contain-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsFlattenedContainListInput+Write.swift")
        val expectedContents = """
extension XmlMapsFlattenedContainListInput {

    static func write(value: XmlMapsFlattenedContainListInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["myMap"].writeMap(value.myMap, valueWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `017 encode map containing timestamp`() {
        val context = setupTests("Isolated/Restxml/xml-maps-timestamp.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsTimestampsInput+Write.swift")
        val expectedContents = """
extension XmlMapsTimestampsInput {

    static func write(value: XmlMapsTimestampsInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["timestampMap"].writeMap(value.timestampMap, valueWritingClosure: SmithyReadWrite.timestampWritingClosure(format: .epochSeconds), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `017 encode flattened map containing timestamp`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-timestamp.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlMapsFlattenedTimestampsInput+Write.swift")
        val expectedContents = """
extension XmlMapsFlattenedTimestampsInput {

    static func write(value: XmlMapsFlattenedTimestampsInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["timestampMap"].writeMap(value.timestampMap, valueWritingClosure: SmithyReadWrite.timestampWritingClosure(format: .epochSeconds), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: true)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `018 encode fooenumMap`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nested-fooenum.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/NestedXmlMapsInput+Write.swift")
        val expectedContents = """
extension NestedXmlMapsInput {

    static func write(value: NestedXmlMapsInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["flatNestedMap"].writeMap(value.flatNestedMap, valueWritingClosure: SmithyReadWrite.mapWritingClosure(valueWritingClosure: SmithyReadWrite.WritingClosureBox<RestXmlProtocolClientTypes.FooEnum>().write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: true)
        try writer["nestedMap"].writeMap(value.nestedMap, valueWritingClosure: SmithyReadWrite.mapWritingClosure(valueWritingClosure: SmithyReadWrite.WritingClosureBox<RestXmlProtocolClientTypes.FooEnum>().write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHTTPRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
