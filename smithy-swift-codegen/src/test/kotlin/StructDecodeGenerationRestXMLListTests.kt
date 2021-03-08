import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test

class StructDecodeGenerationRestXMLListTests {
    @Test
    fun `it creates decodable conformance in Decodable extension`() {
        val context = setupTests("rest-xml-list.smithy", "aws.protocoltests.restxml#RestXml")
        Assertions.assertTrue(context.manifest.hasFile("/example/models/XmlListFlattenedOutputBody+Decodable.swift"))
        Assertions.assertTrue(context.manifest.hasFile("/example/models/XmlListNestedOutputBody+Decodable.swift"))
    }

    @Test
    fun `it creates a structure that has a list of strings for Nested`() {
        val context = setupTests("rest-xml-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getModelFileContents("example", "XmlListNestedOutputBody+Decodable.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            struct XmlListNestedOutputBody: Equatable {
                public let myNestedList: [String]?
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a structure that has a list of strings for Flattened`() {
        val context = setupTests("rest-xml-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getModelFileContents("example", "XmlListFlattenedOutputBody+Decodable.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            struct XmlListFlattenedOutputBody: Equatable {
                public let myFlattenedList: [String]?
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
