package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class RecursiveShapesDecodeXMLGenerationTests {
    @Test
    fun `decode recursive shape`() {
        val context = setupTests("Isolated/Restxml/xml-recursive.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlRecursiveShapesOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlRecursiveShapesOutputBody: Decodable {
                private enum CodingKeys: String, CodingKey {
                    case nested
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let nestedDecoded = try containerValues.decodeIfPresent(RecursiveShapesInputOutputNested1.self, forKey: .nested)
                    nested = nestedDecoded
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `decode recursive nested shape`() {
        /*
        val context = setupTests("Isolated/Restxml/xml-recursive.smithy", "aws.protocoltests.restxml#RestXml")
        print(listFilesFromManifest(context.manifest))
        val contents = getFileContents(context.manifest, "/example/models/XmlEnumsInput+Encodable.swift")
        val expectedContents =
            """

            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
         */
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