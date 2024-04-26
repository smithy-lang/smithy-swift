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

class StructDecodeXMLGenerationTests {
    @Test
    fun `XmlWrappedListOutputBody decodable`() {
        val context = setupTests("Isolated/Restxml/xml-lists-wrapped.smithy", "aws.protocoltests.restxml#RestXml")

        val contents = getFileContents(context.manifest, "/RestXml/models/XmlWrappedListOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlWrappedListOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlWrappedListOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlWrappedListOutput()
            value.myGroceryList = try reader["myGroceryList"].readListIfPresent(memberReadingClosure: Swift.String.readingClosure, memberNodeInfo: "member", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `SimpleScalarPropertiesOutputBody decodable`() {
        val context = setupTests("Isolated/Restxml/xml-scalar.smithy", "aws.protocoltests.restxml#RestXml")

        val contents = getFileContents(context.manifest, "/RestXml/models/SimpleScalarPropertiesOutputBody+Decodable.swift")
        val expectedContents = """
struct SimpleScalarPropertiesOutputBody {
    let stringValue: Swift.String?
    let trueBooleanValue: Swift.Bool?
    let falseBooleanValue: Swift.Bool?
    let byteValue: Swift.Int8?
    let shortValue: Swift.Int16?
    let integerValue: Swift.Int?
    let longValue: Swift.Int?
    let floatValue: Swift.Float?
    let `protocol`: Swift.String?
    let doubleValue: Swift.Double?
}

extension SimpleScalarPropertiesOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<SimpleScalarPropertiesOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = SimpleScalarPropertiesOutput()
            value.stringValue = try reader["stringValue"].readIfPresent()
            value.trueBooleanValue = try reader["trueBooleanValue"].readIfPresent()
            value.falseBooleanValue = try reader["falseBooleanValue"].readIfPresent()
            value.byteValue = try reader["byteValue"].readIfPresent()
            value.shortValue = try reader["shortValue"].readIfPresent()
            value.integerValue = try reader["integerValue"].readIfPresent()
            value.longValue = try reader["longValue"].readIfPresent()
            value.floatValue = try reader["floatValue"].readIfPresent()
            value.`protocol` = try reader["protocol"].readIfPresent()
            value.doubleValue = try reader["DoubleDribble"].readIfPresent()
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `nestednested wrapped list deserialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedNestedWrappedListOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlNestedNestedWrappedListOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlNestedNestedWrappedListOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlNestedNestedWrappedListOutput()
            value.nestedNestedStringList = try reader["nestedNestedStringList"].readListIfPresent(memberReadingClosure: SmithyXML.listReadingClosure(memberReadingClosure: SmithyXML.listReadingClosure(memberReadingClosure: Swift.String.readingClosure, memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `empty lists decode`() {
        val context = setupTests("Isolated/Restxml/xml-lists-empty.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEmptyListsOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlEmptyListsOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlEmptyListsOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlEmptyListsOutput()
            value.stringList = try reader["stringList"].readListIfPresent(memberReadingClosure: Swift.String.readingClosure, memberNodeInfo: "member", isFlattened: false)
            value.stringSet = try reader["stringSet"].readListIfPresent(memberReadingClosure: Swift.String.readingClosure, memberNodeInfo: "member", isFlattened: false)
            value.integerList = try reader["integerList"].readListIfPresent(memberReadingClosure: Swift.Int.readingClosure, memberNodeInfo: "member", isFlattened: false)
            value.booleanList = try reader["booleanList"].readListIfPresent(memberReadingClosure: Swift.Bool.readingClosure, memberNodeInfo: "member", isFlattened: false)
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
