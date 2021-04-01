package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class TimeStampEncodeGenerationTests {
    @Test
    fun `001 encode all timestamps`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlTimestampsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case dateTime
                    case epochSeconds
                    case httpDate
                    case normal
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let dateTime = dateTime {
                        try container.encode(TimestampWrapper(dateTime, format: .dateTime), forKey: .dateTime)
                    }
                    if let epochSeconds = epochSeconds {
                        try container.encode(TimestampWrapper(epochSeconds, format: .epochSeconds), forKey: .epochSeconds)
                    }
                    if let httpDate = httpDate {
                        try container.encode(TimestampWrapper(httpDate, format: .httpDate), forKey: .httpDate)
                    }
                    if let normal = normal {
                        try container.encode(TimestampWrapper(normal, format: .dateTime), forKey: .normal)
                    }
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 encode nested list with timestamps`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlTimestampsNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsNestedInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case nestedTimestampList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let nestedTimestampList = nestedTimestampList {
                        var nestedTimestampListContainer = container.nestedContainer(keyedBy: Key.self, forKey: .nestedTimestampList)
                        for nestedtimestamplist0 in nestedTimestampList {
                            if let nestedtimestamplist0 = nestedtimestamplist0 {
                                var nestedtimestamplist0Container0 = nestedTimestampListContainer.nestedContainer(keyedBy: Key.self, forKey: Key("member"))
                                for timestamp1 in nestedtimestamplist0 {
                                    try nestedtimestamplist0Container0.encode(TimestampWrapper(timestamp1, format: .epochSeconds), forKey: Key("member"))
                                }
                            }
                        }
                    }
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 encode nested list with timestamps httpDate`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlTimestampsNestedHTTPDateInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsNestedHTTPDateInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case nestedTimestampList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let nestedTimestampList = nestedTimestampList {
                        var nestedTimestampListContainer = container.nestedContainer(keyedBy: Key.self, forKey: .nestedTimestampList)
                        for nestedhttpdatetimestamplist0 in nestedTimestampList {
                            if let nestedhttpdatetimestamplist0 = nestedhttpdatetimestamplist0 {
                                var nestedhttpdatetimestamplist0Container0 = nestedTimestampListContainer.nestedContainer(keyedBy: Key.self, forKey: Key("member"))
                                for timestamp1 in nestedhttpdatetimestamplist0 {
                                    try nestedhttpdatetimestamplist0Container0.encode(TimestampWrapper(timestamp1, format: .httpDate), forKey: Key("member"))
                                }
                            }
                        }
                    }
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 encode nested list with timestamps with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlTimestampsNestedXmlNameInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsNestedXmlNameInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case nestedTimestampList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let nestedTimestampList = nestedTimestampList {
                        var nestedTimestampListContainer = container.nestedContainer(keyedBy: Key.self, forKey: .nestedTimestampList)
                        for nestedtimestamplist0 in nestedTimestampList {
                            if let nestedtimestamplist0 = nestedtimestamplist0 {
                                var nestedtimestamplist0Container0 = nestedTimestampListContainer.nestedContainer(keyedBy: Key.self, forKey: Key("nestedTag1"))
                                for timestamp1 in nestedtimestamplist0 {
                                    try nestedtimestamplist0Container0.encode(TimestampWrapper(timestamp1, format: .epochSeconds), forKey: Key("nestedTag2"))
                                }
                            }
                        }
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
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
