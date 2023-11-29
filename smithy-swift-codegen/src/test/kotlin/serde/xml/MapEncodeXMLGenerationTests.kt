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

class MapEncodeXMLGenerationTests {
    @Test
    fun `001 encode map`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                static func writingClosure(_ value: XmlMapsInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myMap")].writeMap(value.myMap, valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.writingClosure(_:to:), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 encode map with name protocol`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsWithNameProtocolInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsWithNameProtocolInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case `protocol` = "protocol"
                }
            
                static func writingClosure(_ value: XmlMapsWithNameProtocolInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("protocol")].writeMap(value.`protocol`, valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.writingClosure(_:to:), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 encode nested wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsNestedInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                static func writingClosure(_ value: XmlMapsNestedInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myMap")].writeMap(value.myMap, valueWritingClosure: SmithyXML.mapWritingClosure(valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.writingClosure(_:to:), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: false), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 encode nested nested wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nestednested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsNestedNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsNestedNestedInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                static func writingClosure(_ value: XmlMapsNestedNestedInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myMap")].writeMap(value.myMap, valueWritingClosure: SmithyXML.mapWritingClosure(valueWritingClosure: SmithyXML.mapWritingClosure(valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.writingClosure(_:to:), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: false), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: false), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 encode flattened map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlFlattenedMapsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlFlattenedMapsInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                static func writingClosure(_ value: XmlFlattenedMapsInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myMap")].writeMap(value.myMap, valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.writingClosure(_:to:), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: true)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `006 encode flattened nested map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedNestedInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                static func writingClosure(_ value: XmlMapsFlattenedNestedInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myMap")].writeMap(value.myMap, valueWritingClosure: SmithyXML.mapWritingClosure(valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.writingClosure(_:to:), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: false), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: true)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `007 encode map with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsXmlNameInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsXmlNameInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                static func writingClosure(_ value: XmlMapsXmlNameInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myMap")].writeMap(value.myMap, valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.writingClosure(_:to:), keyNodeInfo: .init("Attribute"), valueNodeInfo: .init("Setting"), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `008 encode map with xmlname flattened`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsXmlNameFlattenedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsXmlNameFlattenedInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                static func writingClosure(_ value: XmlMapsXmlNameFlattenedInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myMap")].writeMap(value.myMap, valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.writingClosure(_:to:), keyNodeInfo: .init("SomeCustomKey"), valueNodeInfo: .init("SomeCustomValue"), isFlattened: true)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `009 encode map with xmlname nested`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsXmlNameNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsXmlNameNestedInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                static func writingClosure(_ value: XmlMapsXmlNameNestedInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myMap")].writeMap(value.myMap, valueWritingClosure: SmithyXML.mapWritingClosure(valueWritingClosure: RestXmlProtocolClientTypes.GreetingStruct.writingClosure(_:to:), keyNodeInfo: .init("CustomKey2"), valueNodeInfo: .init("CustomValue2"), isFlattened: false), keyNodeInfo: .init("CustomKey1"), valueNodeInfo: .init("CustomValue1"), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `010 encode flattened nested map with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedNestedXmlNameInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedNestedXmlNameInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                static func writingClosure(_ value: XmlMapsFlattenedNestedXmlNameInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myMap")].writeMap(value.myMap, valueWritingClosure: SmithyXML.mapWritingClosure(valueWritingClosure: Swift.String.writingClosure(_:to:), keyNodeInfo: .init("K"), valueNodeInfo: .init("V"), isFlattened: false), keyNodeInfo: .init("yek"), valueNodeInfo: .init("eulav"), isFlattened: true)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `011 encode map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsXmlNamespaceInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsXmlNamespaceInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                static func writingClosure(_ value: XmlMapsXmlNamespaceInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myMap", namespace: .init(prefix: "", uri: "http://boo.com"))].writeMap(value.myMap, valueWritingClosure: Swift.String.writingClosure(_:to:), keyNodeInfo: .init("Quality", namespace: .init(prefix: "", uri: "http://doo.com")), valueNodeInfo: .init("Degree", namespace: .init(prefix: "", uri: "http://eoo.com")), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `012 encode flattened map xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedXmlNamespaceInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedXmlNamespaceInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                static func writingClosure(_ value: XmlMapsFlattenedXmlNamespaceInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myMap", namespace: .init(prefix: "", uri: "http://boo.com"))].writeMap(value.myMap, valueWritingClosure: Swift.String.writingClosure(_:to:), keyNodeInfo: .init("Uid", namespace: .init(prefix: "", uri: "http://doo.com")), valueNodeInfo: .init("Val", namespace: .init(prefix: "", uri: "http://eoo.com")), isFlattened: true)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `013 encode nested map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nested-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsNestedXmlNamespaceInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsNestedXmlNamespaceInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                static func writingClosure(_ value: XmlMapsNestedXmlNamespaceInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myMap", namespace: .init(prefix: "", uri: "http://boo.com"))].writeMap(value.myMap, valueWritingClosure: SmithyXML.mapWritingClosure(valueWritingClosure: Swift.String.writingClosure(_:to:), keyNodeInfo: .init("K", namespace: .init(prefix: "", uri: "http://goo.com")), valueNodeInfo: .init("V", namespace: .init(prefix: "", uri: "http://hoo.com")), isFlattened: false), keyNodeInfo: .init("yek", namespace: .init(prefix: "", uri: "http://doo.com")), valueNodeInfo: .init("eulav", namespace: .init(prefix: "", uri: "http://eoo.com")), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `014 encode nested flattened map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedNestedXmlNamespaceInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedNestedXmlNamespaceInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                static func writingClosure(_ value: XmlMapsFlattenedNestedXmlNamespaceInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myMap", namespace: .init(prefix: "", uri: "http://boo.com"))].writeMap(value.myMap, valueWritingClosure: SmithyXML.mapWritingClosure(valueWritingClosure: Swift.String.writingClosure(_:to:), keyNodeInfo: .init("K", namespace: .init(prefix: "", uri: "http://goo.com")), valueNodeInfo: .init("V", namespace: .init(prefix: "", uri: "http://hoo.com")), isFlattened: false), keyNodeInfo: .init("yek", namespace: .init(prefix: "", uri: "http://doo.com")), valueNodeInfo: .init("eulav", namespace: .init(prefix: "", uri: "http://eoo.com")), isFlattened: true)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `015 encode map containing list`() {
        val context = setupTests("Isolated/Restxml/xml-maps-contain-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsContainListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsContainListInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                static func writingClosure(_ value: XmlMapsContainListInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myMap")].writeMap(value.myMap, valueWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `016 encode flattened map containing list`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-contain-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedContainListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedContainListInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                static func writingClosure(_ value: XmlMapsFlattenedContainListInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myMap")].writeMap(value.myMap, valueWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: true)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `017 encode map containing timestamp`() {
        val context = setupTests("Isolated/Restxml/xml-maps-timestamp.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsTimestampsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsTimestampsInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case timestampMap
                }
            
                static func writingClosure(_ value: XmlMapsTimestampsInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("timestampMap")].writeMap(value.timestampMap, valueWritingClosure: SmithyXML.timestampWritingClosure(format: .epochSeconds), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `017 encode flattened map containing timestamp`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-timestamp.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedTimestampsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedTimestampsInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case timestampMap
                }
            
                static func writingClosure(_ value: XmlMapsFlattenedTimestampsInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("timestampMap")].writeMap(value.timestampMap, valueWritingClosure: SmithyXML.timestampWritingClosure(format: .epochSeconds), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: true)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `018 encode fooenumMap`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nested-fooenum.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/NestedXmlMapsInput+Encodable.swift")
        val expectedContents =
            """
        extension NestedXmlMapsInput: Swift.Encodable {
            enum CodingKeys: Swift.String, Swift.CodingKey {
                case flatNestedMap
                case nestedMap
            }
        
            static func writingClosure(_ value: NestedXmlMapsInput?, to writer: SmithyXML.Writer) throws {
                guard let value else { writer.detach(); return }
                try writer[.init("flatNestedMap")].writeMap(value.flatNestedMap, valueWritingClosure: SmithyXML.mapWritingClosure(valueWritingClosure: RestXmlProtocolClientTypes.FooEnum.writingClosure(_:to:), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: false), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: true)
                try writer[.init("nestedMap")].writeMap(value.nestedMap, valueWritingClosure: SmithyXML.mapWritingClosure(valueWritingClosure: RestXmlProtocolClientTypes.FooEnum.writingClosure(_:to:), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: false), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: false)
            }
        }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
