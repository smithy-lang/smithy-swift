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

class ListDecodeXMLGenerationTests {
    @Test
    fun `001 wrapped list with xmlName`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlListXmlNameOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlListXmlNameOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HttpResponse) async throws -> XmlListXmlNameOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlListXmlNameOutput()
        value.renamedListMembers = try reader["renamed"].readListIfPresent(memberReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), memberNodeInfo: "item", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 wrapped nested list with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlListXmlNameNestedOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlListXmlNameNestedOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HttpResponse) async throws -> XmlListXmlNameNestedOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlListXmlNameNestedOutput()
        value.renamedListMembers = try reader["renamed"].readListIfPresent(memberReadingClosure: SmithyReadWrite.listReadingClosure(memberReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), memberNodeInfo: "subItem", isFlattened: false), memberNodeInfo: "item", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 decode flattened list`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened.smithy", "aws.protocoltests.restxml#RestXml")

        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlFlattenedListOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlFlattenedListOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HttpResponse) async throws -> XmlFlattenedListOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlFlattenedListOutput()
        value.myGroceryList = try reader["myGroceryList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), memberNodeInfo: "member", isFlattened: true)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 decode flattened empty list`() {
        val context = setupTests("Isolated/Restxml/xml-lists-emptyFlattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlEmptyFlattenedListsOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlEmptyFlattenedListsOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HttpResponse) async throws -> XmlEmptyFlattenedListsOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlEmptyFlattenedListsOutput()
        value.booleanList = try reader["booleanList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.ReadingClosures.readBool(from:), memberNodeInfo: "member", isFlattened: false)
        value.integerList = try reader["integerList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.ReadingClosures.readInt(from:), memberNodeInfo: "member", isFlattened: false)
        value.stringList = try reader["stringList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), memberNodeInfo: "member", isFlattened: true)
        value.stringSet = try reader["stringSet"].readListIfPresent(memberReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), memberNodeInfo: "member", isFlattened: true)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 decode nestednested flattened list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlNestedNestedFlattenedListOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlNestedNestedFlattenedListOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HttpResponse) async throws -> XmlNestedNestedFlattenedListOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlNestedNestedFlattenedListOutput()
        value.nestedNestedStringList = try reader["nestedNestedStringList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.listReadingClosure(memberReadingClosure: SmithyReadWrite.listReadingClosure(memberReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: true)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `012 decode list containing map`() {
        val context = setupTests("Isolated/Restxml/xml-lists-contain-map.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlListContainMapOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlListContainMapOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HttpResponse) async throws -> XmlListContainMapOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlListContainMapOutput()
        value.myList = try reader["myList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.mapReadingClosure(valueReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `013 decode flattened list containing map`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened-contain-map.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlListFlattenedContainMapOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlListFlattenedContainMapOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HttpResponse) async throws -> XmlListFlattenedContainMapOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlListFlattenedContainMapOutput()
        value.myList = try reader["myList"].readListIfPresent(memberReadingClosure: SmithyReadWrite.mapReadingClosure(valueReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), memberNodeInfo: "member", isFlattened: true)
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
