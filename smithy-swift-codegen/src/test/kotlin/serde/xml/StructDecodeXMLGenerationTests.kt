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

class StructDecodeXMLGenerationTests {
    @Test
    fun `XmlWrappedListOutputBody decodable`() {
        val context = setupTests("Isolated/Restxml/xml-lists-wrapped.smithy", "aws.protocoltests.restxml#RestXml")

        val contents = getFileContents(context.manifest, "/RestXml/models/XmlWrappedListOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlWrappedListOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HttpResponse) async throws -> XmlWrappedListOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlWrappedListOutput()
        value.myGroceryList = try reader["myGroceryList"].readListIfPresent(memberReadingClosure: Swift.String.read(from:), memberNodeInfo: "member", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `SimpleScalarPropertiesOutputBody decodable`() {
        val context = setupTests("Isolated/Restxml/xml-scalar.smithy", "aws.protocoltests.restxml#RestXml")

        val contents = getFileContents(context.manifest, "/RestXml/models/SimpleScalarPropertiesOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension SimpleScalarPropertiesOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HttpResponse) async throws -> SimpleScalarPropertiesOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = SimpleScalarPropertiesOutput()
        if let fooHeaderValue = httpResponse.headers.value(for: "X-Foo") {
            value.foo = fooHeaderValue
        }
        value.byteValue = try reader["byteValue"].readIfPresent()
        value.doubleValue = try reader["DoubleDribble"].readIfPresent()
        value.falseBooleanValue = try reader["falseBooleanValue"].readIfPresent()
        value.floatValue = try reader["floatValue"].readIfPresent()
        value.integerValue = try reader["integerValue"].readIfPresent()
        value.longValue = try reader["longValue"].readIfPresent()
        value.`protocol` = try reader["protocol"].readIfPresent()
        value.shortValue = try reader["shortValue"].readIfPresent()
        value.stringValue = try reader["stringValue"].readIfPresent()
        value.trueBooleanValue = try reader["trueBooleanValue"].readIfPresent()
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `nestednested wrapped list deserialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedNestedWrappedListOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlNestedNestedWrappedListOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HttpResponse) async throws -> XmlNestedNestedWrappedListOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlNestedNestedWrappedListOutput()
        value.nestedNestedStringList = try reader["nestedNestedStringList"].readListIfPresent(memberReadingClosure: listReadingClosure(memberReadingClosure: listReadingClosure(memberReadingClosure: Swift.String.read(from:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `empty lists decode`() {
        val context = setupTests("Isolated/Restxml/xml-lists-empty.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEmptyListsOutput+HttpResponseBinding.swift")
        val expectedContents = """
extension XmlEmptyListsOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HttpResponse) async throws -> XmlEmptyListsOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = XmlEmptyListsOutput()
        value.booleanList = try reader["booleanList"].readListIfPresent(memberReadingClosure: Swift.Bool.read(from:), memberNodeInfo: "member", isFlattened: false)
        value.integerList = try reader["integerList"].readListIfPresent(memberReadingClosure: Swift.Int.read(from:), memberNodeInfo: "member", isFlattened: false)
        value.stringList = try reader["stringList"].readListIfPresent(memberReadingClosure: Swift.String.read(from:), memberNodeInfo: "member", isFlattened: false)
        value.stringSet = try reader["stringSet"].readListIfPresent(memberReadingClosure: Swift.String.read(from:), memberNodeInfo: "member", isFlattened: false)
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
