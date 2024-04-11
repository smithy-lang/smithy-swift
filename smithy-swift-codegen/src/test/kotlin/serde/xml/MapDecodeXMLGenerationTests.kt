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

class MapDecodeXMLGenerationTests {

    @Test
    fun `001 decode wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsOutput()
            value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.readingClosure, keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 decode wrapped map with name protocol`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsWithNameProtocolOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsWithNameProtocolOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsWithNameProtocolOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsWithNameProtocolOutput()
            value.`protocol` = try reader["protocol"].readMapIfPresent(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.readingClosure, keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 decode nested wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsNestedOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsNestedOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsNestedOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsNestedOutput()
            value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: SmithyXML.mapReadingClosure(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.readingClosure, keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 decode nested nested wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nestednested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsNestedNestedOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsNestedNestedOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsNestedNestedOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsNestedNestedOutput()
            value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: SmithyXML.mapReadingClosure(valueReadingClosure: SmithyXML.mapReadingClosure(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.readingClosure, keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 decode flattened map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlFlattenedMapsOutputBody+Read.swift")
        val expectedContents = """
extension XmlFlattenedMapsOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlFlattenedMapsOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlFlattenedMapsOutput()
            value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.readingClosure, keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: true)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `006 decode flattened nested map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedNestedOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsFlattenedNestedOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsFlattenedNestedOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsFlattenedNestedOutput()
            value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: SmithyXML.mapReadingClosure(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.readingClosure, keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: true)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `007 decode map with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsXmlNameOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsXmlNameOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsXmlNameOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsXmlNameOutput()
            value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.readingClosure, keyNodeInfo: "Attribute", valueNodeInfo: "Setting", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `008 decode map with xmlname flattened`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsXmlNameFlattenedOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsXmlNameFlattenedOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsXmlNameFlattenedOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsXmlNameFlattenedOutput()
            value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.readingClosure, keyNodeInfo: "SomeCustomKey", valueNodeInfo: "SomeCustomValue", isFlattened: true)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `009 decode map with xmlname nested`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsXmlNameNestedOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsXmlNameNestedOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsXmlNameNestedOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsXmlNameNestedOutput()
            value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: SmithyXML.mapReadingClosure(valueReadingClosure: RestXmlProtocolClientTypes.GreetingStruct.readingClosure, keyNodeInfo: "CustomKey2", valueNodeInfo: "CustomValue2", isFlattened: false), keyNodeInfo: "CustomKey1", valueNodeInfo: "CustomValue1", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `011 decode flattened nested map with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedNestedXmlNameOutputBody+Decodable.swift")
        val expectedContents = """
extension XmlMapsFlattenedNestedXmlNameOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsFlattenedNestedXmlNameOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsFlattenedNestedXmlNameOutput()
            value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: SmithyXML.mapReadingClosure(valueReadingClosure: Swift.String.readingClosure, keyNodeInfo: "K", valueNodeInfo: "V", isFlattened: false), keyNodeInfo: "yek", valueNodeInfo: "eulav", isFlattened: true)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `011 decode map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsXmlNamespaceOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsXmlNamespaceOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsXmlNamespaceOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsXmlNamespaceOutput()
            value.myMap = try reader[.init("myMap", namespaceDef: .init(prefix: "", uri: "http://boo.com"))].readMapIfPresent(valueReadingClosure: Swift.String.readingClosure, keyNodeInfo: .init("Quality", namespaceDef: .init(prefix: "", uri: "http://doo.com")), valueNodeInfo: .init("Degree", namespaceDef: .init(prefix: "", uri: "http://eoo.com")), isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `012 decode flattened map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedXmlNamespaceOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsFlattenedXmlNamespaceOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsFlattenedXmlNamespaceOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsFlattenedXmlNamespaceOutput()
            value.myMap = try reader[.init("myMap", namespaceDef: .init(prefix: "", uri: "http://boo.com"))].readMapIfPresent(valueReadingClosure: Swift.String.readingClosure, keyNodeInfo: .init("Uid", namespaceDef: .init(prefix: "", uri: "http://doo.com")), valueNodeInfo: .init("Val", namespaceDef: .init(prefix: "", uri: "http://eoo.com")), isFlattened: true)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `013 decode nested map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nested-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsNestedXmlNamespaceOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsNestedXmlNamespaceOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsNestedXmlNamespaceOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsNestedXmlNamespaceOutput()
            value.myMap = try reader[.init("myMap", namespaceDef: .init(prefix: "", uri: "http://boo.com"))].readMapIfPresent(valueReadingClosure: SmithyXML.mapReadingClosure(valueReadingClosure: Swift.String.readingClosure, keyNodeInfo: .init("K", namespaceDef: .init(prefix: "", uri: "http://goo.com")), valueNodeInfo: .init("V", namespaceDef: .init(prefix: "", uri: "http://hoo.com")), isFlattened: false), keyNodeInfo: .init("yek", namespaceDef: .init(prefix: "", uri: "http://doo.com")), valueNodeInfo: .init("eulav", namespaceDef: .init(prefix: "", uri: "http://eoo.com")), isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `014 decode nested flattened map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedNestedXmlNamespaceOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsFlattenedNestedXmlNamespaceOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsFlattenedNestedXmlNamespaceOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsFlattenedNestedXmlNamespaceOutput()
            value.myMap = try reader[.init("myMap", namespaceDef: .init(prefix: "", uri: "http://boo.com"))].readMapIfPresent(valueReadingClosure: SmithyXML.mapReadingClosure(valueReadingClosure: Swift.String.readingClosure, keyNodeInfo: .init("K", namespaceDef: .init(prefix: "", uri: "http://goo.com")), valueNodeInfo: .init("V", namespaceDef: .init(prefix: "", uri: "http://hoo.com")), isFlattened: false), keyNodeInfo: .init("yek", namespaceDef: .init(prefix: "", uri: "http://doo.com")), valueNodeInfo: .init("eulav", namespaceDef: .init(prefix: "", uri: "http://eoo.com")), isFlattened: true)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `015 decode map containing list`() {
        val context = setupTests("Isolated/Restxml/xml-maps-contain-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsContainListOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsContainListOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsContainListOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsContainListOutput()
            value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: SmithyXML.listReadingClosure(memberReadingClosure: Swift.String.readingClosure, memberNodeInfo: "member", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `016 decode flattened map containing list`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-contain-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedContainListOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsFlattenedContainListOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsFlattenedContainListOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsFlattenedContainListOutput()
            value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: SmithyXML.listReadingClosure(memberReadingClosure: Swift.String.readingClosure, memberNodeInfo: "member", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: true)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `017 decode map containing timestamp`() {
        val context = setupTests("Isolated/Restxml/xml-maps-timestamp.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsTimestampsOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsTimestampsOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsTimestampsOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsTimestampsOutput()
            value.timestampMap = try reader["timestampMap"].readMapIfPresent(valueReadingClosure: SmithyXML.timestampReadingClosure(format: .epochSeconds), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `018 decode flattened map containing timestamp`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-timestamp.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedTimestampsOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsFlattenedTimestampsOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsFlattenedTimestampsOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsFlattenedTimestampsOutput()
            value.timestampMap = try reader["timestampMap"].readMapIfPresent(valueReadingClosure: SmithyXML.timestampReadingClosure(format: .epochSeconds), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: true)
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `019 two maps that may conflict with KeyValue`() {
        val context = setupTests("Isolated/Restxml/xml-maps-2x.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsTwoOutputBody+Read.swift")
        val expectedContents = """
extension XmlMapsTwoOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<XmlMapsTwoOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = XmlMapsTwoOutput()
            value.myMap = try reader["myMap"].readMapIfPresent(valueReadingClosure: Swift.String.readingClosure, keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
            value.mySecondMap = try reader["mySecondMap"].readMapIfPresent(valueReadingClosure: Swift.String.readingClosure, keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
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
