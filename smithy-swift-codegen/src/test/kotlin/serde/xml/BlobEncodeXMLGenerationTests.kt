package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class BlobEncodeXMLGenerationTests {
    @Test
    fun `encode blob`() {
        val context = setupTests("Isolated/Restxml/xml-blobs.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlBlobsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlBlobsInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case data
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let data = data {
                        try container.encode(data, forKey: Key("data"))
                    }
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `encode nested blob`() {
        val context = setupTests("Isolated/Restxml/xml-blobs.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlBlobsNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlBlobsNestedInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case nestedBlobList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let nestedBlobList = nestedBlobList {
                        var nestedBlobListContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("nestedBlobList"))
                        for nestedbloblist0 in nestedBlobList {
                            if let nestedbloblist0 = nestedbloblist0 {
                                var nestedbloblist0Container0 = nestedBlobListContainer.nestedContainer(keyedBy: Key.self, forKey: Key("member"))
                                for blob1 in nestedbloblist0 {
                                    try nestedbloblist0Container0.encode(blob1, forKey: Key("member"))
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
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
