import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.AddOperationShapes
import software.amazon.smithy.swift.codegen.RecursiveShapeBoxer

class StructDecodeGenerationRestXMLListTests {
    var model = javaClass.getResource("rest-xml-list.smithy").asSmithy()
    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings("aws.protocoltests.restxml#RestXml", "RestXml", "2019-12-16", "Rest Xml Protocol")
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        model = RecursiveShapeBoxer.transform(model)
        return model.newTestContext("aws.protocoltests.restxml#RestXml", model.defaultSettings(), MockHttpRestXMLProtocolGenerator())
    }
    val newTestContext = newTestContext()

    init {
        newTestContext.generator.generateDeserializers(newTestContext.generationCtx)
        newTestContext.generator.generateCodableConformanceForNestedTypes(newTestContext.generationCtx)
        newTestContext.generationCtx.delegator.flushWriters()
    }

    @Test
    fun `it creates decodable conformance in Decodable extension`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/XmlListFlattenedOutputBody+Decodable.swift"))
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/XmlListNestedOutputBody+Decodable.swift"))
    }

    @Test
    fun `it creates a structure that has a list of strings for Nested`() {
        val contents = getModelFileContents("example", "XmlListNestedOutputBody+Decodable.swift", newTestContext.manifest)
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
        val contents = getModelFileContents("example", "XmlListFlattenedOutputBody+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            struct XmlListFlattenedOutputBody: Equatable {
                public let myFlattenedList: [String]?
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
