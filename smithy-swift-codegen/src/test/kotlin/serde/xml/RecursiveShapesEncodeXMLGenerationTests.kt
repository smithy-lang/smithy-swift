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

class RecursiveShapesEncodeXMLGenerationTests {
    @Test
    fun `001 encode recursive shape Nested1`() {
        val context = setupTests("Isolated/Restxml/xml-recursive.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/RecursiveShapesInputOutputNested1+ReadWrite.swift")
        val expectedContents = """
extension RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1 {

    static func write(value: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["foo"].write(value.foo)
        try writer["nested"].write(value.nested, with: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2.write(value:to:))
    }

    static func read(from reader: SmithyXML.Reader) throws -> RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1 {
        guard reader.hasContent else { throw SmithyReadWrite.ReaderError.requiredValueNotPresent }
        var value = RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1()
        value.foo = try reader["foo"].readIfPresent()
        value.nested = try reader["nested"].readIfPresent(with: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2.read(from:))
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `encode recursive shape Nested2`() {
        val context = setupTests("Isolated/Restxml/xml-recursive.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/RecursiveShapesInputOutputNested2+ReadWrite.swift")
        val expectedContents = """
extension RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2 {

    static func write(value: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["bar"].write(value.bar)
        try writer["recursiveMember"].write(value.recursiveMember, with: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1.write(value:to:))
    }

    static func read(from reader: SmithyXML.Reader) throws -> RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2 {
        guard reader.hasContent else { throw SmithyReadWrite.ReaderError.requiredValueNotPresent }
        var value = RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2()
        value.bar = try reader["bar"].readIfPresent()
        value.recursiveMember = try reader["recursiveMember"].readIfPresent(with: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1.read(from:))
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `encode recursive nested shape`() {
        val context = setupTests("Isolated/Restxml/xml-recursive-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlNestedRecursiveShapesInput+Write.swift")
        val expectedContents = """
extension XmlNestedRecursiveShapesInput {

    static func write(value: XmlNestedRecursiveShapesInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["nestedRecursiveList"].writeList(value.nestedRecursiveList, memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1.write(value:to:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
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
