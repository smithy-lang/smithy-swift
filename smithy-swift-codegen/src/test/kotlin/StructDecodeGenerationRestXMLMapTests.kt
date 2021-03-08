import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test

class StructDecodeGenerationRestXMLMapTests {

    @Test
    fun `it creates decodable conformance in Decodable extension`() {
        val context = setupTests("rest-xml-map.smithy", "aws.protocoltests.restxml#RestXml")

        Assertions.assertTrue(context.manifest.hasFile("/example/models/FlattenedXmlMapOutputBody+Decodable.swift"))
        Assertions.assertTrue(context.manifest.hasFile("/example/models/NestedXmlMapOutputBody+Decodable.swift"))
    }

    @Test
    fun `it creates a structure that has a map of strings for Nested`() {
        val context = setupTests("rest-xml-map.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getModelFileContents("example", "NestedXmlMapOutputBody+Decodable.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            struct NestedXmlMapOutputBody: Equatable {
                public let myNestedMap: [String:FooEnum]?
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a structure that has a map of strings for Flattened`() {
        val context = setupTests("rest-xml-map.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getModelFileContents("example", "FlattenedXmlMapOutputBody+Decodable.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            struct FlattenedXmlMapOutputBody: Equatable {
                public let myFlattenedMap: [String:FooEnum]?
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }

        context.generator.generateDeserializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
