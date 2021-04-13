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
        val contents = getFileContents(context.manifest, "/example/models/XmlTimestampsOutputBody+Decodable.swift")
        val expectedContents = """
        extension XmlTimestampsOutputBody: Decodable {
            enum CodingKeys: String, CodingKey {
                case dateTime
                case epochSeconds
                case httpDate
                case normal
            }
        
            public init (from decoder: Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                let normalDecoded = try containerValues.decodeIfPresent(String.self, forKey: .normal)
                var normalBuffer:Date? = nil
                if let normalDecoded = normalDecoded {
                    normalBuffer = try TimestampWrapperDecoder.parseDateStringValue(normalDecoded, format: .dateTime)
                }
                normal = normalBuffer
                let dateTimeDecoded = try containerValues.decodeIfPresent(String.self, forKey: .dateTime)
                var dateTimeBuffer:Date? = nil
                if let dateTimeDecoded = dateTimeDecoded {
                    dateTimeBuffer = try TimestampWrapperDecoder.parseDateStringValue(dateTimeDecoded, format: .dateTime)
                }
                dateTime = dateTimeBuffer
                let epochSecondsDecoded = try containerValues.decodeIfPresent(String.self, forKey: .epochSeconds)
                var epochSecondsBuffer:Date? = nil
                if let epochSecondsDecoded = epochSecondsDecoded {
                    epochSecondsBuffer = try TimestampWrapperDecoder.parseDateStringValue(epochSecondsDecoded, format: .epochSeconds)
                }
                epochSeconds = epochSecondsBuffer
                let httpDateDecoded = try containerValues.decodeIfPresent(String.self, forKey: .httpDate)
                var httpDateBuffer:Date? = nil
                if let httpDateDecoded = httpDateDecoded {
                    httpDateBuffer = try TimestampWrapperDecoder.parseDateStringValue(httpDateDecoded, format: .httpDate)
                }
                httpDate = httpDateBuffer
            }
        }
        """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 decode nested timestamps`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlTimestampsNestedOutputBody+Decodable.swift")
        val expectedContents = """
        extension XmlTimestampsNestedOutputBody: Decodable {
            enum CodingKeys: String, CodingKey {
                case nestedTimestampList
            }
        
            public init (from decoder: Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.nestedTimestampList) {
                    struct KeyVal0{struct member{}}
                    let nestedTimestampListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<KeyVal0.member>.CodingKeys.self, forKey: .nestedTimestampList)
                    if let nestedTimestampListWrappedContainer = nestedTimestampListWrappedContainer {
                        let nestedTimestampListContainer = try nestedTimestampListWrappedContainer.decodeIfPresent([[String]?].self, forKey: .member)
                        var nestedTimestampListBuffer:[[Date]?]? = nil
                        if let nestedTimestampListContainer = nestedTimestampListContainer {
                            nestedTimestampListBuffer = [[Date]?]()
                            var listBuffer0: [Date]? = nil
                            for listContainer0 in nestedTimestampListContainer {
                                listBuffer0 = [Date]()
                                if let listContainer0 = listContainer0 {
                                    for timestampContainer1 in listContainer0 {
                                        try listBuffer0?.append(TimestampWrapperDecoder.parseDateStringValue(timestampContainer1, format: .epochSeconds))
                                    }
                                }
                                nestedTimestampListBuffer?.append(listBuffer0)
                            }
                        }
                        nestedTimestampList = nestedTimestampListBuffer
                    } else {
                        nestedTimestampList = []
                    }
                } else {
                    nestedTimestampList = nil
                }
            }
        }
        """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 decode nested timestamps HttpDate`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlTimestampsNestedHTTPDateOutputBody+Decodable.swift")
        val expectedContents = """
        extension XmlTimestampsNestedHTTPDateOutputBody: Decodable {
            enum CodingKeys: String, CodingKey {
                case nestedTimestampList
            }
        
            public init (from decoder: Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.nestedTimestampList) {
                    struct KeyVal0{struct member{}}
                    let nestedTimestampListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<KeyVal0.member>.CodingKeys.self, forKey: .nestedTimestampList)
                    if let nestedTimestampListWrappedContainer = nestedTimestampListWrappedContainer {
                        let nestedTimestampListContainer = try nestedTimestampListWrappedContainer.decodeIfPresent([[String]?].self, forKey: .member)
                        var nestedTimestampListBuffer:[[Date]?]? = nil
                        if let nestedTimestampListContainer = nestedTimestampListContainer {
                            nestedTimestampListBuffer = [[Date]?]()
                            var listBuffer0: [Date]? = nil
                            for listContainer0 in nestedTimestampListContainer {
                                listBuffer0 = [Date]()
                                if let listContainer0 = listContainer0 {
                                    for timestampContainer1 in listContainer0 {
                                        try listBuffer0?.append(TimestampWrapperDecoder.parseDateStringValue(timestampContainer1, format: .httpDate))
                                    }
                                }
                                nestedTimestampListBuffer?.append(listBuffer0)
                            }
                        }
                        nestedTimestampList = nestedTimestampListBuffer
                    } else {
                        nestedTimestampList = []
                    }
                } else {
                    nestedTimestampList = nil
                }
            }
        }
        """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `004 decode nested timestamps xmlName`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlTimestampsNestedXmlNameOutputBody+Decodable.swift")
        val expectedContents = """
        extension XmlTimestampsNestedXmlNameOutputBody: Decodable {
            enum CodingKeys: String, CodingKey {
                case nestedTimestampList
            }
        
            public init (from decoder: Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.nestedTimestampList) {
                    struct KeyVal0{struct nestedTag1{}}
                    let nestedTimestampListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<KeyVal0.nestedTag1>.CodingKeys.self, forKey: .nestedTimestampList)
                    if let nestedTimestampListWrappedContainer = nestedTimestampListWrappedContainer {
                        let nestedTimestampListContainer = try nestedTimestampListWrappedContainer.decodeIfPresent([[String]?].self, forKey: .member)
                        var nestedTimestampListBuffer:[[Date]?]? = nil
                        if let nestedTimestampListContainer = nestedTimestampListContainer {
                            nestedTimestampListBuffer = [[Date]?]()
                            var listBuffer0: [Date]? = nil
                            for listContainer0 in nestedTimestampListContainer {
                                listBuffer0 = [Date]()
                                if let listContainer0 = listContainer0 {
                                    for timestampContainer1 in listContainer0 {
                                        try listBuffer0?.append(TimestampWrapperDecoder.parseDateStringValue(timestampContainer1, format: .epochSeconds))
                                    }
                                }
                                nestedTimestampListBuffer?.append(listBuffer0)
                            }
                        }
                        nestedTimestampList = nestedTimestampListBuffer
                    } else {
                        nestedTimestampList = []
                    }
                } else {
                    nestedTimestampList = nil
                }
            }
        }
        """.trimIndent()

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
