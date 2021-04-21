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
        val contents = getFileContents(context.manifest, "/example/models/XmlUnionShape+Codable.swift")
        val expectedContents =
            """
            extension XmlUnionShape: Codable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case dataValue
                    case doubleValue
                    case mapValue
                    case sdkUnknown
                    case stringList
                    case structValue
                    case timeStampValue
                    case unionValue
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    switch self {
                        case let .dataValue(dataValue):
                            if let dataValue = dataValue {
                                try container.encode(dataValue, forKey: Key("dataValue"))
                            }
                        case let .doubleValue(doubleValue):
                            if let doubleValue = doubleValue {
                                try container.encode(doubleValue, forKey: Key("doubleValue"))
                            }
                        case let .mapValue(mapValue):
                            if let mapValue = mapValue {
                                var mapValueContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("mapValue"))
                                for (stringKey0, stringValue0) in mapValue {
                                    var entryContainer0 = mapValueContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                                    var keyContainer0 = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("K"))
                                    try keyContainer0.encode(stringKey0, forKey: Key(""))
                                    var valueContainer0 = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("V"))
                                    try valueContainer0.encode(stringValue0, forKey: Key(""))
                                }
                            }
                        case let .stringList(stringList):
                            if let stringList = stringList {
                                var stringListContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("stringList"))
                                for string0 in stringList {
                                    try stringListContainer.encode(string0, forKey: Key("member"))
                                }
                            }
                        case let .structValue(structValue):
                            if let structValue = structValue {
                                try container.encode(structValue, forKey: Key("structValue"))
                            }
                        case let .timeStampValue(timeStampValue):
                            if let timeStampValue = timeStampValue {
                                try container.encode(TimestampWrapper(timeStampValue, format: .dateTime), forKey: Key("timeStampValue"))
                            }
                        case let .unionValue(unionValue):
                            if let unionValue = unionValue {
                                try container.encode(unionValue, forKey: Key("unionValue"))
                            }
                        case let .sdkUnknown(sdkUnknown):
                            try container.encode(sdkUnknown, forKey: Key("sdkUnknown"))
                    }
                }
            
                public init (from decoder: Decoder) throws {
                    let values = try decoder.container(keyedBy: CodingKeys.self)
                    let doubleValueDecoded = try values.decodeIfPresent(Double.self, forKey: .doubleValue)
                    if let doubleValue = doubleValueDecoded {
                        self = .doubleValue(doubleValue)
                        return
                    }
                    if values.contains(.dataValue) {
                        do {
                            let dataValueDecoded = try values.decodeIfPresent(Data.self, forKey: .dataValue)
                            if let dataValue = dataValueDecoded {
                                self = .dataValue(dataValue)
                                return
                            }
                        } catch {
                            if let dataValue = "".data(using: .utf8) {
                                self = .dataValue(dataValue)
                                return
                            }
                        }
                    } else {
                        //No-op
                    }
                    let unionValueDecoded = try values.decodeIfPresent(Box<XmlUnionShape>.self, forKey: .unionValue)
                    if let unionValue = unionValueDecoded {
                        self = .unionValue(unionValue.value)
                        return
                    }
                    let structValueDecoded = try values.decodeIfPresent(XmlNestedUnionStruct.self, forKey: .structValue)
                    if let structValue = structValueDecoded {
                        self = .structValue(structValue)
                        return
                    }
                    struct KeyVal0{struct K{}; struct V{}}
                    if values.contains(.mapValue) {
                        let mapValueWrappedContainer = values.nestedContainerNonThrowable(keyedBy: MapEntry<String, String, KeyVal0.K, KeyVal0.V>.CodingKeys.self, forKey: .mapValue)
                        if let mapValueWrappedContainer = mapValueWrappedContainer {
                            let mapValueContainer = try mapValueWrappedContainer.decodeIfPresent([MapKeyValue<String, String, KeyVal0.K, KeyVal0.V>].self, forKey: .entry)
                            var mapValueBuffer: [String:String]? = nil
                            if let mapValueContainer = mapValueContainer {
                                mapValueBuffer = [String:String]()
                                for stringContainer0 in mapValueContainer {
                                    mapValueBuffer?[stringContainer0.key] = stringContainer0.value
                                }
                            }
                            if let mapValue = mapValueBuffer {
                                self = .mapValue(mapValue)
                                return
                            }
                        } else {
                            self = .mapValue([:])
                            return
                        }
                    } else {
                        //No-op
                    }
                    if values.contains(.stringList) {
                        struct KeyVal0{struct member{}}
                        let stringListWrappedContainer = values.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .stringList)
                        if let stringListWrappedContainer = stringListWrappedContainer {
                            let stringListContainer = try stringListWrappedContainer.decodeIfPresent([String].self, forKey: .member)
                            var stringListBuffer:[String]? = nil
                            if let stringListContainer = stringListContainer {
                                stringListBuffer = [String]()
                                for stringContainer0 in stringListContainer {
                                    stringListBuffer?.append(stringContainer0)
                                }
                            }
                            if let stringList = stringListBuffer {
                                self = .stringList(stringList)
                                return
                            }
                        } else {
                            self = .stringList([])
                            return
                        }
                    } else {
                        //No-op
                    }
                    let timeStampValueDecoded = try values.decodeIfPresent(String.self, forKey: .timeStampValue)
                    var timeStampValueBuffer:Date? = nil
                    if let timeStampValueDecoded = timeStampValueDecoded {
                        timeStampValueBuffer = try TimestampWrapperDecoder.parseDateStringValue(timeStampValueDecoded, format: .dateTime)
                    }
                    if let timeStampValue = timeStampValueBuffer {
                        self = .timeStampValue(timeStampValue)
                        return
                    }
                    self = .sdkUnknown("")
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 XmlUnionShape should be marked as indirect`() {
        val context = setupTests("Isolated/Restxml/xml-unions.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlUnionShape.swift")
        val expectedContents =
            """
            public indirect enum XmlUnionShape: Equatable {
                case doubleValue(Double?)
                case dataValue(Data?)
                case unionValue(XmlUnionShape?)
                case structValue(XmlNestedUnionStruct?)
                case mapValue([String:String]?)
                case stringList([String]?)
                case timeStampValue(Date?)
                case sdkUnknown(String?)
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
