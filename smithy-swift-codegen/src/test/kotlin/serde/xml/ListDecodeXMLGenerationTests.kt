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

class ListDecodeXMLGenerationTests {
    @Test
    fun `001 wrapped list with xmlName`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListXmlNameOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlListXmlNameOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlListXmlNameOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlListXmlNameOutput()
            value.renamedListMembers = try reader["renamed"].readListIfPresent(memberReadingClosure: Swift.String.readingClosure, memberNodeInfo: "item", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 wrapped nested list with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListXmlNameNestedOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlListXmlNameNestedOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlListXmlNameNestedOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlListXmlNameNestedOutput()
            value.renamedListMembers = try reader["renamed"].readListIfPresent(memberReadingClosure: SmithyXML.listReadingClosure(memberReadingClosure: Swift.String.readingClosure, memberNodeInfo: "subItem", isFlattened: false), memberNodeInfo: "item", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 decode flattened list`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened.smithy", "aws.protocoltests.restxml#RestXml")

        val contents = getFileContents(context.manifest, "/RestXml/models/XmlFlattenedListOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlFlattenedListOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlFlattenedListOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlFlattenedListOutput()
            value.myGroceryList = try reader["myGroceryList"].readListIfPresent(memberReadingClosure: Swift.String.readingClosure, memberNodeInfo: "member", isFlattened: true)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 decode flattened empty list`() {
        val context = setupTests("Isolated/Restxml/xml-lists-emptyFlattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEmptyFlattenedListsOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlEmptyFlattenedListsOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlEmptyFlattenedListsOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlEmptyFlattenedListsOutput()
            value.stringList = try reader["stringList"].readListIfPresent(memberReadingClosure: Swift.String.readingClosure, memberNodeInfo: "member", isFlattened: true)
            value.stringSet = try reader["stringSet"].readListIfPresent(memberReadingClosure: Swift.String.readingClosure, memberNodeInfo: "member", isFlattened: true)
            value.integerList = try reader["integerList"].readListIfPresent(memberReadingClosure: Swift.Int.readingClosure, memberNodeInfo: "member", isFlattened: false)
            value.booleanList = try reader["booleanList"].readListIfPresent(memberReadingClosure: Swift.Bool.readingClosure, memberNodeInfo: "member", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 decode nestednested flattened list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedNestedFlattenedListOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlNestedNestedFlattenedListOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlNestedNestedFlattenedListOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlNestedNestedFlattenedListOutput()
            value.nestedNestedStringList = try reader["nestedNestedStringList"].readListIfPresent(memberReadingClosure: SmithyXML.listReadingClosure(memberReadingClosure: SmithyXML.listReadingClosure(memberReadingClosure: Swift.String.readingClosure, memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: true)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `012 decode list containing map`() {
        val context = setupTests("Isolated/Restxml/xml-lists-contain-map.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListContainMapOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlListContainMapOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlListContainMapOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlListContainMapOutput()
            value.myList = try reader["myList"].readListIfPresent(memberReadingClosure: SmithyXML.mapReadingClosure(valueReadingClosure: Swift.String.readingClosure, keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `013 decode flattened list containing map`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened-contain-map.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListFlattenedContainMapOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlListFlattenedContainMapOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlListFlattenedContainMapOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlListFlattenedContainMapOutput()
            value.myList = try reader["myList"].readListIfPresent(memberReadingClosure: SmithyXML.mapReadingClosure(valueReadingClosure: Swift.String.readingClosure, keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), memberNodeInfo: "member", isFlattened: true)
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
