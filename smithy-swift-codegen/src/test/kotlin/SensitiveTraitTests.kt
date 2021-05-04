import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class SensitiveTraitTests {
    @Test
    fun `SensitiveTraitInRequestInput+CustomStringConvertible`() {
        val context = setupTests("sensitive-trait-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/example/models/SensitiveTraitInRequestInput+CustomStringConvertable.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """

            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `SensitiveTraitInRequestOutput+CustomStringConvertible`() {
        val context = setupTests("sensitive-trait-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/example/models/SensitiveTraitInRequestOutput+CustomStringConvertible.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension SensitiveTraitInRequestOutput: CustomStringConvertible {
                public var description: String {
                    return "** redacted **"
                }
            }
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