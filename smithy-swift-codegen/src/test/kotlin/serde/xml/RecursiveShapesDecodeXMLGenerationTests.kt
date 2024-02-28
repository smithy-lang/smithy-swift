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

class RecursiveShapesDecodeXMLGenerationTests {
    @Test
    fun `decode recursive shape`() {
        val context = setupTests("Isolated/Restxml/xml-recursive.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlRecursiveShapesOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlRecursiveShapesOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlRecursiveShapesOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlRecursiveShapesOutput()
            value.nested = try reader["nested"].readIfPresent(readingClosure: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1.readingClosure)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `decode recursive nested shape`() {
        val context = setupTests("Isolated/Restxml/xml-recursive-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedRecursiveShapesOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlNestedRecursiveShapesOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlNestedRecursiveShapesOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlNestedRecursiveShapesOutput()
            value.nestedRecursiveList = try reader["nestedRecursiveList"].readListIfPresent(memberReadingClosure: SmithyXML.listReadingClosure(memberReadingClosure: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1.readingClosure, memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
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
