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

class EnumEncodeXMLGenerationTests {
    @Test
    fun `001 encode enum`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumsInput+Write.swift")
        val expectedContents = """
extension XmlEnumsInput {

    static func write(value: XmlEnumsInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["fooEnum1"].write(value.fooEnum1)
        try writer["fooEnum2"].write(value.fooEnum2)
        try writer["fooEnum3"].write(value.fooEnum3)
        try writer["fooEnumList"].writeList(value.fooEnumList, memberWritingClosure: RestXmlProtocolClientTypes.FooEnum.write(value:to:), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 encode nested enum`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumsNestedInput+Write.swift")
        val expectedContents = """
extension XmlEnumsNestedInput {

    static func write(value: XmlEnumsNestedInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["nestedEnumsList"].writeList(value.nestedEnumsList, memberWritingClosure: listWritingClosure(memberWritingClosure: RestXmlProtocolClientTypes.FooEnum.write(value:to:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
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
