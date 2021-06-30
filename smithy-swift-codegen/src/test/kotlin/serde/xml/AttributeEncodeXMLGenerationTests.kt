package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class AttributeEncodeXMLGenerationTests {
    @Test
    fun `001 xml attributes encoding for input type`() {
        val context = setupTests("Isolated/Restxml/xml-attr.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlAttributesInput+DynamicNodeEncoding.swift")
        val expectedContents =
            """
            extension XmlAttributesInput: DynamicNodeEncoding {
                public static func nodeEncoding(for key: CodingKey) -> NodeEncoding {
                    let codingKeys = [
                        "test"
                    ]
                    if let key = key as? Key {
                        if codingKeys.contains(key.stringValue) {
                            return .attribute
                        }
                    }
                    return .element
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 creates encodable`() {
        val context = setupTests("Isolated/Restxml/xml-attr.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlAttributesInput+Extensions.swift")
        val expectedContents =
            """
            extension XmlAttributesInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case attr = "test"
                    case foo
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let attr = attr {
                        try container.encode(attr, forKey: Key("test"))
                    }
                    if let foo = foo {
                        try container.encode(foo, forKey: Key("foo"))
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
