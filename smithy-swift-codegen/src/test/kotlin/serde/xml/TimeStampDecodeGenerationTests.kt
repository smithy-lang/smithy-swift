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

class TimeStampDecodeGenerationTests {
    @Test
    fun `001 decode all timestamps`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsOutputResponseBody+Decodable.swift")
        val expectedContents = """
        extension XmlTimestampsOutputResponseBody: Swift.Decodable {
            enum CodingKeys: Swift.String, Swift.CodingKey {
                case dateTime
                case epochSeconds
                case httpDate
                case normal
            }
        
            public init (from decoder: Swift.Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                let normalDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .normal)
                var normalBuffer:Runtime.Date? = nil
                if let normalDecoded = normalDecoded {
                    normalBuffer = try Runtime.TimestampWrapperDecoder.parseDateStringValue(normalDecoded, format: .dateTime)
                }
                normal = normalBuffer
                let dateTimeDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .dateTime)
                var dateTimeBuffer:Runtime.Date? = nil
                if let dateTimeDecoded = dateTimeDecoded {
                    dateTimeBuffer = try Runtime.TimestampWrapperDecoder.parseDateStringValue(dateTimeDecoded, format: .dateTime)
                }
                dateTime = dateTimeBuffer
                let epochSecondsDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .epochSeconds)
                var epochSecondsBuffer:Runtime.Date? = nil
                if let epochSecondsDecoded = epochSecondsDecoded {
                    epochSecondsBuffer = try Runtime.TimestampWrapperDecoder.parseDateStringValue(epochSecondsDecoded, format: .epochSeconds)
                }
                epochSeconds = epochSecondsBuffer
                let httpDateDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .httpDate)
                var httpDateBuffer:Runtime.Date? = nil
                if let httpDateDecoded = httpDateDecoded {
                    httpDateBuffer = try Runtime.TimestampWrapperDecoder.parseDateStringValue(httpDateDecoded, format: .httpDate)
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsNestedOutputResponseBody+Decodable.swift")
        val expectedContents = """
        extension XmlTimestampsNestedOutputResponseBody: Swift.Decodable {
            enum CodingKeys: Swift.String, Swift.CodingKey {
                case nestedTimestampList
            }
        
            public init (from decoder: Swift.Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.nestedTimestampList) {
                    struct KeyVal0{struct member{}}
                    let nestedTimestampListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: XMLRuntime.CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .nestedTimestampList)
                    if let nestedTimestampListWrappedContainer = nestedTimestampListWrappedContainer {
                        let nestedTimestampListContainer = try nestedTimestampListWrappedContainer.decodeIfPresent([[Swift.String]].self, forKey: .member)
                        var nestedTimestampListBuffer:[[Runtime.Date]]? = nil
                        if let nestedTimestampListContainer = nestedTimestampListContainer {
                            nestedTimestampListBuffer = [[Runtime.Date]]()
                            var listBuffer0: [Runtime.Date]? = nil
                            for listContainer0 in nestedTimestampListContainer {
                                listBuffer0 = [Runtime.Date]()
                                for timestampContainer1 in listContainer0 {
                                    try listBuffer0?.append(Runtime.TimestampWrapperDecoder.parseDateStringValue(timestampContainer1, format: .epochSeconds))
                                }
                                if let listBuffer0 = listBuffer0 {
                                    nestedTimestampListBuffer?.append(listBuffer0)
                                }
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsNestedHTTPDateOutputResponseBody+Decodable.swift")
        val expectedContents = """
        extension XmlTimestampsNestedHTTPDateOutputResponseBody: Swift.Decodable {
            enum CodingKeys: Swift.String, Swift.CodingKey {
                case nestedTimestampList
            }
        
            public init (from decoder: Swift.Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.nestedTimestampList) {
                    struct KeyVal0{struct member{}}
                    let nestedTimestampListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: XMLRuntime.CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .nestedTimestampList)
                    if let nestedTimestampListWrappedContainer = nestedTimestampListWrappedContainer {
                        let nestedTimestampListContainer = try nestedTimestampListWrappedContainer.decodeIfPresent([[Swift.String]].self, forKey: .member)
                        var nestedTimestampListBuffer:[[Runtime.Date]]? = nil
                        if let nestedTimestampListContainer = nestedTimestampListContainer {
                            nestedTimestampListBuffer = [[Runtime.Date]]()
                            var listBuffer0: [Runtime.Date]? = nil
                            for listContainer0 in nestedTimestampListContainer {
                                listBuffer0 = [Runtime.Date]()
                                for timestampContainer1 in listContainer0 {
                                    try listBuffer0?.append(Runtime.TimestampWrapperDecoder.parseDateStringValue(timestampContainer1, format: .httpDate))
                                }
                                if let listBuffer0 = listBuffer0 {
                                    nestedTimestampListBuffer?.append(listBuffer0)
                                }
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsNestedXmlNameOutputResponseBody+Decodable.swift")
        val expectedContents = """
        extension XmlTimestampsNestedXmlNameOutputResponseBody: Swift.Decodable {
            enum CodingKeys: Swift.String, Swift.CodingKey {
                case nestedTimestampList
            }
        
            public init (from decoder: Swift.Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.nestedTimestampList) {
                    struct KeyVal0{struct nestedTag1{}}
                    let nestedTimestampListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: XMLRuntime.CollectionMemberCodingKey<KeyVal0.nestedTag1>.CodingKeys.self, forKey: .nestedTimestampList)
                    if let nestedTimestampListWrappedContainer = nestedTimestampListWrappedContainer {
                        let nestedTimestampListContainer = try nestedTimestampListWrappedContainer.decodeIfPresent([[Swift.String]].self, forKey: .member)
                        var nestedTimestampListBuffer:[[Runtime.Date]]? = nil
                        if let nestedTimestampListContainer = nestedTimestampListContainer {
                            nestedTimestampListBuffer = [[Runtime.Date]]()
                            var listBuffer0: [Runtime.Date]? = nil
                            for listContainer0 in nestedTimestampListContainer {
                                listBuffer0 = [Runtime.Date]()
                                for timestampContainer1 in listContainer0 {
                                    try listBuffer0?.append(Runtime.TimestampWrapperDecoder.parseDateStringValue(timestampContainer1, format: .epochSeconds))
                                }
                                if let listBuffer0 = listBuffer0 {
                                    nestedTimestampListBuffer?.append(listBuffer0)
                                }
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
