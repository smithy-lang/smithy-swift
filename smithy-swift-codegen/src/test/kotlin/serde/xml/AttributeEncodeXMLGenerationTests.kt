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
        val contents = getFileContents(context.manifest, "/example/models/XmlAttributesInput+DynamicNodeEncoding.swift")
        val expectedContents =
            """
            extension XmlAttributesInput: DynamicNodeEncoding {
                public static func nodeEncoding(for key: CodingKey) -> NodeEncoding {
                    switch(key) {
                        case XmlAttributesInput.CodingKeys.foo: return .element
                        case XmlAttributesInput.CodingKeys.attr: return .attribute
                        default:
                            return .element
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 creates DynanmicNodeDecoding for input body`() {
        val context = setupTests("Isolated/Restxml/xml-attr.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlAttributesInputBody+DynamicNodeDecoding.swift")
        val expectedContents =
            """
            extension XmlAttributesInputBody: DynamicNodeDecoding {
                public static func nodeDecoding(for key: CodingKey) -> NodeDecoding {
                    switch(key) {
                        case XmlAttributesInputBody.CodingKeys.foo: return .element
                        case XmlAttributesInputBody.CodingKeys.attr: return .attribute
                        default:
                            return .element
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
