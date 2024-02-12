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

class RecursiveShapesEncodeXMLGenerationTests {
    @Test
    fun `001 encode recursive shape Nested1`() {
        val context = setupTests("Isolated/Restxml/xml-recursive.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/RecursiveShapesInputOutputNested1+Codable.swift")
        val expectedContents = """
extension RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1 {

    static func writingClosure(_ value: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["foo"].write(value.foo)
        try writer["nested"].write(value.nested, writingClosure: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2.writingClosure(_:to:))
    }

    static var readingClosure: SmithyReadWrite.ReadingClosure<RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1()
            value.foo = try reader["foo"].readIfPresent()
            value.nested = try reader["nested"].readIfPresent(readingClosure: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2.readingClosure)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `encode recursive shape Nested2`() {
        val context = setupTests("Isolated/Restxml/xml-recursive.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/RecursiveShapesInputOutputNested2+Codable.swift")
        val expectedContents = """
extension RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2 {

    static func writingClosure(_ value: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["bar"].write(value.bar)
        try writer["recursiveMember"].write(value.recursiveMember, writingClosure: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1.writingClosure(_:to:))
    }

    static var readingClosure: SmithyReadWrite.ReadingClosure<RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2()
            value.bar = try reader["bar"].readIfPresent()
            value.recursiveMember = try reader["recursiveMember"].readIfPresent(readingClosure: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1.readingClosure)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `encode recursive nested shape`() {
        val context = setupTests("Isolated/Restxml/xml-recursive-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedRecursiveShapesInput+Encodable.swift")
        val expectedContents = """
extension XmlNestedRecursiveShapesInput {
    static func writingClosure(_ value: XmlNestedRecursiveShapesInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["nestedRecursiveList"].writeList(value.nestedRecursiveList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1.writingClosure(_:to:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
