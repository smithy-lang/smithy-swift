import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.model.AddOperationShapes

class HttpUrlPathProviderTests {
    @Test
    fun `001 it builds url path provider smoke test`() {
        val context = setupTests("http-binding-protocol-generator-test.smithy")
        val contents = getModelFileContents("Sources/example", "SmokeTestInput+UrlPathProvider.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension SmokeTestInput {

    static func urlPathProvider(_ value: SmokeTestInput) -> Swift.String? {
        guard let label1 = value.label1 else {
            return nil
        }
        return "/smoketest/\(label1.urlPercentEncoding())/foo"
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 it handles required http labels`() {
        val context = setupTests("http-binding-protocol-generator-test.smithy")
        val contents = getModelFileContents("Sources/example", "RequiredHttpFieldsInput+UrlPathProvider.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()

        // All http labels are implicitly required, even if the smithy spec doesn't specify the required trait
        val expectedContents = """
extension RequiredHttpFieldsInput {

    static func urlPathProvider(_ value: RequiredHttpFieldsInput) -> Swift.String? {
        guard let label1 = value.label1 else {
            return nil
        }
        guard let label2 = value.label2 else {
            return nil
        }
        return "/RequiredHttpFields/\(label1.urlPercentEncoding())/\(label2.urlPercentEncoding())"
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String): TestContext {
        var model = javaClass.getResource(smithyFile).asSmithy()
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        val context = model.newTestContext()
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateDeserializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
