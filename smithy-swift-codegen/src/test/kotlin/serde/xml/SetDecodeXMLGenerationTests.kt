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

class SetDecodeXMLGenerationTests {
    @Test
    fun `XmlEnumSetOutputBody decodable`() {
        val context = setupTests("Isolated/Restxml/xml-sets.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumSetOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlEnumSetOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlEnumSetOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlEnumSetOutput()
            value.fooEnumSet = try reader["fooEnumSet"].readListIfPresent(memberReadingClosure: RestXmlProtocolClientTypes.FooEnum.readingClosure, memberNodeInfo: "member", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `XmlEnumNestedSetOutputBody nested decodable`() {
        val context = setupTests("Isolated/Restxml/xml-sets-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumNestedSetOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlEnumNestedSetOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlEnumNestedSetOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlEnumNestedSetOutput()
            value.fooEnumSet = try reader["fooEnumSet"].readListIfPresent(memberReadingClosure: SmithyXML.listReadingClosure(memberReadingClosure: RestXmlProtocolClientTypes.FooEnum.readingClosure, memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
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
