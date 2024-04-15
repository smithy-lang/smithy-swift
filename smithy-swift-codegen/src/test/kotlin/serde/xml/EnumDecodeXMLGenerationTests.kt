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

class EnumDecodeXMLGenerationTests {

    @Test
    fun `decode enum`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumsOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlEnumsOutput {

    static var httpBinding: SmithyReadWrite.WireResponseOutputBinding<ClientRuntime.HttpResponse, XmlEnumsOutput, SmithyXML.Reader> {
        { httpResponse, responseDocumentClosure in
            let responseReader = try await responseDocumentClosure(httpResponse)
            let reader = responseReader
            var value = XmlEnumsOutput()
            value.fooEnum1 = try reader["fooEnum1"].readIfPresent()
            value.fooEnum2 = try reader["fooEnum2"].readIfPresent()
            value.fooEnum3 = try reader["fooEnum3"].readIfPresent()
            value.fooEnumList = try reader["fooEnumList"].readListIfPresent(memberReadingClosure: RestXmlProtocolClientTypes.FooEnum.read(from:), memberNodeInfo: "member", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `decode enum nested`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumsNestedOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlEnumsNestedOutput {

    static var httpBinding: SmithyReadWrite.WireResponseOutputBinding<ClientRuntime.HttpResponse, XmlEnumsNestedOutput, SmithyXML.Reader> {
        { httpResponse, responseDocumentClosure in
            let responseReader = try await responseDocumentClosure(httpResponse)
            let reader = responseReader
            var value = XmlEnumsNestedOutput()
            value.nestedEnumsList = try reader["nestedEnumsList"].readListIfPresent(memberReadingClosure: listReadingClosure(memberReadingClosure: RestXmlProtocolClientTypes.FooEnum.read(from:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
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
        context.generator.generateDeserializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
