package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class EnumEncodeXMLGenerationTests {
    @Test
    fun `001 encode enum`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlEnumsInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case fooEnum1
                    case fooEnum2
                    case fooEnum3
                    case fooEnumList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let fooEnum1 = fooEnum1 {
                        try container.encode(fooEnum1, forKey: Key("fooEnum1"))
                    }
                    if let fooEnum2 = fooEnum2 {
                        try container.encode(fooEnum2, forKey: Key("fooEnum2"))
                    }
                    if let fooEnum3 = fooEnum3 {
                        try container.encode(fooEnum3, forKey: Key("fooEnum3"))
                    }
                    if let fooEnumList = fooEnumList {
                        var fooEnumListContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("fooEnumList"))
                        for fooenum0 in fooEnumList {
                            try fooEnumListContainer.encode(fooenum0, forKey: Key("member"))
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 encode nested enum`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumsNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlEnumsNestedInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case nestedEnumsList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let nestedEnumsList = nestedEnumsList {
                        var nestedEnumsListContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("nestedEnumsList"))
                        for nestedenumslist0 in nestedEnumsList {
                            var nestedenumslist0Container0 = nestedEnumsListContainer.nestedContainer(keyedBy: Key.self, forKey: Key("member"))
                            for fooenum1 in nestedenumslist0 {
                                try nestedenumslist0Container0.encode(fooenum1, forKey: Key("member"))
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
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
