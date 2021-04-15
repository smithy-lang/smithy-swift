package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class StructEncodeXMLGenerationTests {
    @Test
    fun `simpleScalar serialization`() {
        val context = setupTests("Isolated/Restxml/xml-scalar.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/SimpleScalarPropertiesInput+Encodable.swift")
        val expectedContents =
            """
            extension SimpleScalarPropertiesInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case byteValue
                    case doubleValue = "DoubleDribble"
                    case falseBooleanValue
                    case floatValue
                    case integerValue
                    case longValue
                    case `protocol` = "protocol"
                    case shortValue
                    case stringValue
                    case trueBooleanValue
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let byteValue = byteValue {
                        try container.encode(byteValue, forKey: Key("byteValue"))
                    }
                    if let doubleValue = doubleValue {
                        try container.encode(doubleValue, forKey: Key("DoubleDribble"))
                    }
                    if let falseBooleanValue = falseBooleanValue {
                        try container.encode(falseBooleanValue, forKey: Key("falseBooleanValue"))
                    }
                    if let floatValue = floatValue {
                        try container.encode(floatValue, forKey: Key("floatValue"))
                    }
                    if let integerValue = integerValue {
                        try container.encode(integerValue, forKey: Key("integerValue"))
                    }
                    if let longValue = longValue {
                        try container.encode(longValue, forKey: Key("longValue"))
                    }
                    if let `protocol` = `protocol` {
                        try container.encode(`protocol`, forKey: Key("protocol"))
                    }
                    if let shortValue = shortValue {
                        try container.encode(shortValue, forKey: Key("shortValue"))
                    }
                    if let stringValue = stringValue {
                        try container.encode(stringValue, forKey: Key("stringValue"))
                    }
                    if let trueBooleanValue = trueBooleanValue {
                        try container.encode(trueBooleanValue, forKey: Key("trueBooleanValue"))
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `008 structure xmlName`() {
        val context = setupTests("Isolated/Restxml/xml-lists-structure.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/StructureListMember+Codable.swift")
        val expectedContents =
            """
            extension StructureListMember: Codable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case a = "value"
                    case b = "other"
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let a = a {
                        try container.encode(a, forKey: Key("value"))
                    }
                    if let b = b {
                        try container.encode(b, forKey: Key("other"))
                    }
                }

                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let aDecoded = try containerValues.decodeIfPresent(String.self, forKey: .a)
                    a = aDecoded
                    let bDecoded = try containerValues.decodeIfPresent(String.self, forKey: .b)
                    b = bDecoded
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
