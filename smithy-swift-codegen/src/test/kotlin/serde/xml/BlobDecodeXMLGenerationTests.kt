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

class BlobDecodeXMLGenerationTests {

    @Test
    fun `decode blob`() {
        val context = setupTests("Isolated/Restxml/xml-blobs.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlBlobsOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlBlobsOutput {

    static var httpBinding: SmithyReadWrite.WireResponseOutputBinding<ClientRuntime.HttpResponse, XmlBlobsOutput, SmithyXML.Reader> {
        { httpResponse, responseDocumentClosure in
            let responseReader = try await responseDocumentClosure(httpResponse)
            let reader = responseReader
            var value = XmlBlobsOutput()
            value.data = try reader["data"].readIfPresent()
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `decode blob nested`() {
        val context = setupTests("Isolated/Restxml/xml-blobs.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlBlobsNestedOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlBlobsNestedOutput {

    static var httpBinding: SmithyReadWrite.WireResponseOutputBinding<ClientRuntime.HttpResponse, XmlBlobsNestedOutput, SmithyXML.Reader> {
        { httpResponse, responseDocumentClosure in
            let responseReader = try await responseDocumentClosure(httpResponse)
            let reader = responseReader
            var value = XmlBlobsNestedOutput()
            value.nestedBlobList = try reader["nestedBlobList"].readListIfPresent(memberReadingClosure: listReadingClosure(memberReadingClosure: ClientRuntime.Data.read(from:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
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
