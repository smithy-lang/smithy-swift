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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumsOutputBody+Decodable.swift")
        val expectedContents = """
struct XmlEnumsOutputBody {
    let fooEnum1: RestXmlProtocolClientTypes.FooEnum?
    let fooEnum2: RestXmlProtocolClientTypes.FooEnum?
    let fooEnum3: RestXmlProtocolClientTypes.FooEnum?
    let fooEnumList: [RestXmlProtocolClientTypes.FooEnum]?
}

extension XmlEnumsOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlEnumsOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlEnumsOutput()
            value.fooEnum1 = try reader["fooEnum1"].readIfPresent()
            value.fooEnum2 = try reader["fooEnum2"].readIfPresent()
            value.fooEnum3 = try reader["fooEnum3"].readIfPresent()
            value.fooEnumList = try reader["fooEnumList"].readListIfPresent(memberReadingClosure: RestXmlProtocolClientTypes.FooEnum.readingClosure, memberNodeInfo: "member", isFlattened: false)
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumsNestedOutputBody+Decodable.swift")
        val expectedContents = """
struct XmlEnumsNestedOutputBody {
    let nestedEnumsList: [[RestXmlProtocolClientTypes.FooEnum]]?
}

extension XmlEnumsNestedOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlEnumsNestedOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlEnumsNestedOutput()
            value.nestedEnumsList = try reader["nestedEnumsList"].readListIfPresent(memberReadingClosure: SmithyXML.listReadingClosure(memberReadingClosure: RestXmlProtocolClientTypes.FooEnum.readingClosure, memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
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
