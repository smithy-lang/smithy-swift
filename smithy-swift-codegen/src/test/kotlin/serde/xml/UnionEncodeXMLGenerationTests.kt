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

class UnionEncodeXMLGenerationTests {
    @Test
    fun `001 XmlUnionShape+Codable`() {
        val context = setupTests("Isolated/Restxml/xml-unions.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlUnionShape+Codable.swift")
        val expectedContents =
            """
extension RestXmlProtocolClientTypes.XmlUnionShape: Swift.Codable {
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case datavalue = "dataValue"
        case doublevalue = "doubleValue"
        case mapvalue = "mapValue"
        case sdkUnknown
        case stringlist = "stringList"
        case structvalue = "structValue"
        case timestampvalue = "timeStampValue"
        case unionvalue = "unionValue"
    }

    static func writingClosure(_ value: RestXmlProtocolClientTypes.XmlUnionShape?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        switch value {
            case let .datavalue(datavalue):
                try writer[.init("dataValue")].write(datavalue)
            case let .doublevalue(doublevalue):
                try writer[.init("doubleValue")].write(doublevalue)
            case let .mapvalue(mapvalue):
                try writer[.init("mapValue")].writeMap(mapvalue, valueWritingClosure: Swift.String.writingClosure(_:to:), keyNodeInfo: .init("K"), valueNodeInfo: .init("V"), isFlattened: false)
            case let .stringlist(stringlist):
                try writer[.init("stringList")].writeList(stringlist, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false)
            case let .structvalue(structvalue):
                try RestXmlProtocolClientTypes.XmlNestedUnionStruct.writingClosure(structvalue, to: writer[.init("structValue")])
            case let .timestampvalue(timestampvalue):
                try writer[.init("timeStampValue")].writeTimestamp(timestampvalue, format: .dateTime)
            case let .unionvalue(unionvalue):
                try RestXmlProtocolClientTypes.XmlUnionShape.writingClosure(unionvalue, to: writer[.init("unionValue")])
            case let .sdkUnknown(sdkUnknown):
                try writer[.init("sdkUnknown")].write(sdkUnknown)
        }
    }

    public init(from decoder: Swift.Decoder) throws {
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        let key = containerValues.allKeys.first
        switch key {
            case .doublevalue:
                let doublevalueDecoded = try containerValues.decode(Swift.Double.self, forKey: .doublevalue)
                self = .doublevalue(doublevalueDecoded)
            case .datavalue:
                let datavalueDecoded = try containerValues.decode(ClientRuntime.Data.self, forKey: .datavalue)
                self = .datavalue(datavalueDecoded)
            case .unionvalue:
                let unionvalueDecoded = try containerValues.decode(RestXmlProtocolClientTypes.XmlUnionShape.self, forKey: .unionvalue)
                self = .unionvalue(unionvalueDecoded)
            case .structvalue:
                let structvalueDecoded = try containerValues.decode(RestXmlProtocolClientTypes.XmlNestedUnionStruct.self, forKey: .structvalue)
                self = .structvalue(structvalueDecoded)
            case .mapvalue:
                struct KeyVal0{struct K{}; struct V{}}
                let mapvalueWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, Swift.String, KeyVal0.K, KeyVal0.V>.CodingKeys.self, forKey: .mapvalue)
                if let mapvalueWrappedContainer = mapvalueWrappedContainer {
                    let mapvalueContainer = try mapvalueWrappedContainer.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, Swift.String, KeyVal0.K, KeyVal0.V>].self, forKey: .entry)
                    var mapvalueBuffer: [Swift.String:Swift.String]? = nil
                    if let mapvalueContainer = mapvalueContainer {
                        mapvalueBuffer = [Swift.String:Swift.String]()
                        for stringContainer0 in mapvalueContainer {
                            mapvalueBuffer?[stringContainer0.key] = stringContainer0.value
                        }
                    }
                    self = .mapvalue(mapvalueBuffer)
                } else {
                    self = .mapvalue([:])
                }
            case .stringlist:
                struct KeyVal0{struct member{}}
                let stringlistWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .stringlist)
                if let stringlistWrappedContainer = stringlistWrappedContainer {
                    let stringlistContainer = try stringlistWrappedContainer.decodeIfPresent([Swift.String].self, forKey: .member)
                    var stringlistBuffer:[Swift.String]? = nil
                    if let stringlistContainer = stringlistContainer {
                        stringlistBuffer = [Swift.String]()
                        for stringContainer0 in stringlistContainer {
                            stringlistBuffer?.append(stringContainer0)
                        }
                    }
                    self = .stringlist(stringlistBuffer)
                } else {
                    self = .stringlist([])
                }
            case .timestampvalue:
                let timestampvalueDecoded = try containerValues.decodeTimestamp(.dateTime, forKey: .timestampvalue)
                self = .timestampvalue(timestampvalueDecoded)
            default:
                self = .sdkUnknown("")
        }
    }
}
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 XmlUnionShape should be marked as indirect`() {
        val context = setupTests("Isolated/Restxml/xml-unions.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlUnionShape.swift")
        val expectedContents =
            """
            extension ExampleClientTypes {
                public indirect enum XmlUnionShape: Swift.Equatable {
                    case doublevalue(Swift.Double)
                    case datavalue(ClientRuntime.Data)
                    case unionvalue(ExampleClientTypes.XmlUnionShape)
                    case structvalue(ExampleClientTypes.XmlNestedUnionStruct)
                    case mapvalue([Swift.String:Swift.String])
                    case stringlist([Swift.String])
                    case timestampvalue(ClientRuntime.Date)
                    case sdkUnknown(Swift.String)
                }
            
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
