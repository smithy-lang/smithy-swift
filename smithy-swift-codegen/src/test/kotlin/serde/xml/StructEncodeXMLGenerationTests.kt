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

class StructEncodeXMLGenerationTests {
    @Test
    fun `simpleScalar serialization`() {
        val context = setupTests("Isolated/Restxml/xml-scalar.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/SimpleScalarPropertiesInput+Encodable.swift")
        val expectedContents = """
extension SimpleScalarPropertiesInput {
    static func writingClosure(_ value: SimpleScalarPropertiesInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["byteValue"].write(value.byteValue)
        try writer["DoubleDribble"].write(value.doubleValue)
        try writer["falseBooleanValue"].write(value.falseBooleanValue)
        try writer["floatValue"].write(value.floatValue)
        try writer["integerValue"].write(value.integerValue)
        try writer["longValue"].write(value.longValue)
        try writer["protocol"].write(value.`protocol`)
        try writer["shortValue"].write(value.shortValue)
        try writer["stringValue"].write(value.stringValue)
        try writer["trueBooleanValue"].write(value.trueBooleanValue)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `008 structure xmlName`() {
        val context = setupTests("Isolated/Restxml/xml-lists-structure.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/StructureListMember+Codable.swift")
        val expectedContents = """
extension RestXmlProtocolClientTypes.StructureListMember {

    static func writingClosure(_ value: RestXmlProtocolClientTypes.StructureListMember?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer["value"].write(value.a)
        try writer["other"].write(value.b)
    }

    static var readingClosure: SmithyReadWrite.ReadingClosure<RestXmlProtocolClientTypes.StructureListMember, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = RestXmlProtocolClientTypes.StructureListMember()
            value.a = try reader["value"].readIfPresent()
            value.b = try reader["other"].readIfPresent()
            return value
        }
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
