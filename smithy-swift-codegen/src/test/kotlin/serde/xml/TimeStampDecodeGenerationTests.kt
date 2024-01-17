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

class TimeStampDecodeGenerationTests {
    @Test
    fun `001 decode all timestamps`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlTimestampsOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlTimestampsOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlTimestampsOutput()
            value.normal = try reader["normal"].readTimestampIfPresent(format: .dateTime)
            value.dateTime = try reader["dateTime"].readTimestampIfPresent(format: .dateTime)
            value.epochSeconds = try reader["epochSeconds"].readTimestampIfPresent(format: .epochSeconds)
            value.httpDate = try reader["httpDate"].readTimestampIfPresent(format: .httpDate)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 decode nested timestamps`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsNestedOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlTimestampsNestedOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlTimestampsNestedOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlTimestampsNestedOutput()
            value.nestedTimestampList = try reader["nestedTimestampList"].readListIfPresent(memberReadingClosure: SmithyXML.listReadingClosure(memberReadingClosure: SmithyXML.timestampReadingClosure(format: .epochSeconds), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 decode nested timestamps HttpDate`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsNestedHTTPDateOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlTimestampsNestedHTTPDateOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlTimestampsNestedHTTPDateOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlTimestampsNestedHTTPDateOutput()
            value.nestedTimestampList = try reader["nestedTimestampList"].readListIfPresent(memberReadingClosure: SmithyXML.listReadingClosure(memberReadingClosure: SmithyXML.timestampReadingClosure(format: .httpDate), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
            return value
        }
    }
}
"""

        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `004 decode nested timestamps xmlName`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsNestedXmlNameOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlTimestampsNestedXmlNameOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlTimestampsNestedXmlNameOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlTimestampsNestedXmlNameOutput()
            value.nestedTimestampList = try reader["nestedTimestampList"].readListIfPresent(memberReadingClosure: SmithyXML.listReadingClosure(memberReadingClosure: SmithyXML.timestampReadingClosure(format: .epochSeconds), memberNodeInfo: "nestedTag2", isFlattened: false), memberNodeInfo: "nestedTag1", isFlattened: false)
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
