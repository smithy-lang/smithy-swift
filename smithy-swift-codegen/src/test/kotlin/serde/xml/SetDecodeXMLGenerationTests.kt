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

class SetDecodeXMLGenerationTests {
    @Test
    fun `XmlEnumSetOutputBody decodable`() {
        val context = setupTests("Isolated/Restxml/xml-sets.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumSetOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlEnumSetOutput {

    static func httpOutput(from httpResponse: ClientRuntime.HttpResponse) async throws -> XmlEnumSetOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlEnumSetOutput()
        value.fooEnumSet = try reader["fooEnumSet"].readListIfPresent(memberReadingClosure: RestXmlProtocolClientTypes.FooEnum.read(from:), memberNodeInfo: "member", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `XmlEnumNestedSetOutputBody nested decodable`() {
        val context = setupTests("Isolated/Restxml/xml-sets-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumNestedSetOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlEnumNestedSetOutput {

    static func httpOutput(from httpResponse: ClientRuntime.HttpResponse) async throws -> XmlEnumNestedSetOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlEnumNestedSetOutput()
        value.fooEnumSet = try reader["fooEnumSet"].readListIfPresent(memberReadingClosure: listReadingClosure(memberReadingClosure: RestXmlProtocolClientTypes.FooEnum.read(from:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHTTPRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateDeserializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
