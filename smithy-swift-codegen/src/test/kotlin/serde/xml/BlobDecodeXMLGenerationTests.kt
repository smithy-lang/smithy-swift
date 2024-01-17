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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlBlobsOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlBlobsOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlBlobsOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlBlobsNestedOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlBlobsNestedOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlBlobsNestedOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlBlobsNestedOutput()
            value.nestedBlobList = try reader["nestedBlobList"].readListIfPresent(memberReadingClosure: SmithyXML.listReadingClosure(memberReadingClosure: ClientRuntime.Data.readingClosure, memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
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
