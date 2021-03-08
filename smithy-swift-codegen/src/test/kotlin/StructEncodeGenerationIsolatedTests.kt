import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test

class StructEncodeGenerationIsolatedTests {
    @Test
    fun `BlobInput`() {
        val context = setupTests("Isolated/BlobInput.smithy", "com.test#Example")
        Assertions.assertTrue(context.manifest.hasFile("/example/models/BlobInputInput+Encodable.swift"))
    }

    @Test
    fun `BlobInput Contents`() {
        val context = setupTests("Isolated/BlobInput.smithy", "com.test#Example")
        val contents = getModelFileContents("example", "BlobInputInput+Encodable.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
    }

    @Test
    fun `EnumInput`() {
        val testContext = setupTests("Isolated/EnumInput.smithy", "com.test#Example")
        Assertions.assertTrue(testContext.manifest.hasFile("/example/models/EnumInputInput+Encodable.swift"))
    }

    @Test
    fun `EnumInput Contents`() {
        val context = setupTests("Isolated/EnumInput.smithy", "com.test#Example")
        print(listFilesFromManifest(context.manifest))
        val contents = getFileContents(context.manifest, "/example/models/EnumInputInput.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct EnumInputInput: Equatable {
                public let enumHeader: MyEnum?
                public let nestedWithEnum: NestedEnum?
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
