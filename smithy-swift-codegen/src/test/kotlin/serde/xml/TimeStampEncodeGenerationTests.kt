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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsInput: Swift.Encodable, ClientRuntime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case dateTime
                    case epochSeconds
                    case httpDate
                    case normal
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let dateTime = dateTime {
                        try container.encode(ClientRuntime.TimestampWrapper(dateTime, format: .dateTime), forKey: ClientRuntime.Key("dateTime"))
                    }
                    if let epochSeconds = epochSeconds {
                        try container.encode(ClientRuntime.TimestampWrapper(epochSeconds, format: .epochSeconds), forKey: ClientRuntime.Key("epochSeconds"))
                    }
                    if let httpDate = httpDate {
                        try container.encode(ClientRuntime.TimestampWrapper(httpDate, format: .httpDate), forKey: ClientRuntime.Key("httpDate"))
                    }
                    if let normal = normal {
                        try container.encode(ClientRuntime.TimestampWrapper(normal, format: .dateTime), forKey: ClientRuntime.Key("normal"))
                    }
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 encode nested list with timestamps`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsNestedInput: Swift.Encodable, ClientRuntime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedTimestampList
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let nestedTimestampList = nestedTimestampList {
                        var nestedTimestampListContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("nestedTimestampList"))
                        for nestedtimestamplist0 in nestedTimestampList {
                            var nestedtimestamplist0Container0 = nestedTimestampListContainer.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("member"))
                            for timestamp1 in nestedtimestamplist0 {
                                try nestedtimestamplist0Container0.encode(ClientRuntime.TimestampWrapper(timestamp1, format: .epochSeconds), forKey: ClientRuntime.Key("member"))
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsNestedHTTPDateInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsNestedHTTPDateInput: Swift.Encodable, ClientRuntime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedTimestampList
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let nestedTimestampList = nestedTimestampList {
                        var nestedTimestampListContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("nestedTimestampList"))
                        for nestedhttpdatetimestamplist0 in nestedTimestampList {
                            var nestedhttpdatetimestamplist0Container0 = nestedTimestampListContainer.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("member"))
                            for timestamp1 in nestedhttpdatetimestamplist0 {
                                try nestedhttpdatetimestamplist0Container0.encode(ClientRuntime.TimestampWrapper(timestamp1, format: .httpDate), forKey: ClientRuntime.Key("member"))
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsNestedXmlNameInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsNestedXmlNameInput: Swift.Encodable, ClientRuntime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedTimestampList
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let nestedTimestampList = nestedTimestampList {
                        var nestedTimestampListContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("nestedTimestampList"))
                        for nestedtimestamplist0 in nestedTimestampList {
                            var nestedtimestamplist0Container0 = nestedTimestampListContainer.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("nestedTag1"))
                            for timestamp1 in nestedtimestamplist0 {
                                try nestedtimestamplist0Container0.encode(ClientRuntime.TimestampWrapper(timestamp1, format: .epochSeconds), forKey: ClientRuntime.Key("nestedTag2"))
                            }
                        }
                    }
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 encode all timestamps, withxmlName`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsXmlNameInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsXmlNameInput: Swift.Encodable, ClientRuntime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case dateTime
                    case normal = "notNormalName"
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let dateTime = dateTime {
                        try container.encode(ClientRuntime.TimestampWrapper(dateTime, format: .dateTime), forKey: ClientRuntime.Key("dateTime"))
                    }
                    if let normal = normal {
                        try container.encode(ClientRuntime.TimestampWrapper(normal, format: .dateTime), forKey: ClientRuntime.Key("notNormalName"))
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
