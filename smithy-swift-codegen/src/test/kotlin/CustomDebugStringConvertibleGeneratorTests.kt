import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.DefaultClientConfigurationIntegration

class CustomDebugStringConvertibleGeneratorTests {
    @Test
    fun `list with sensitive trait gets redacted correctly`() {
        val context = setupTests("custom-debug-string-convertible-generator-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/RestJson/models/GetFooOutput+CustomDebugStringConvertible.swift")
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce("listWithSensitiveTrait: \\\"CONTENT_REDACTED\\\"")
    }

    @Test
    fun `list with member shape that targets a shape with sensitive trait gets redacted correctly`() {
        val context = setupTests("custom-debug-string-convertible-generator-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/RestJson/models/GetFooOutput+CustomDebugStringConvertible.swift")
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce("listWithSensitiveTargetedByMember: \\\"CONTENT_REDACTED\\\"")
    }

    @Test
    fun `map with sensitive trait gets redacted correctly`() {
        val context = setupTests("custom-debug-string-convertible-generator-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/RestJson/models/GetFooOutput+CustomDebugStringConvertible.swift")
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce("mapWithSensitiveTrait: \\\"CONTENT_REDACTED\\\"")
    }

    @Test
    fun `map with key that targets a shape with sensitive trait gets redacted correctly`() {
        val context = setupTests("custom-debug-string-convertible-generator-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/RestJson/models/GetFooOutput+CustomDebugStringConvertible.swift")
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce("mapWithSensitiveTargetedByKey: [keys: \\\"CONTENT_REDACTED\\\", values: \\(Swift.String(describing: mapWithSensitiveTargetedByKey?.values))]")
    }

    @Test
    fun `map with value that targets a shape with sensitive trait gets redacted correctly`() {
        val context = setupTests("custom-debug-string-convertible-generator-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/RestJson/models/GetFooOutput+CustomDebugStringConvertible.swift")
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce("mapWithSensitiveTargetedByValue: [keys: \\(Swift.String(describing: mapWithSensitiveTargetedByValue?.keys)), values: \\\"CONTENT_REDACTED\\\"]")
    }

    @Test
    fun `map with key and value that target shapes with sensitive trait gets redacted correctly`() {
        val context = setupTests("custom-debug-string-convertible-generator-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/RestJson/models/GetFooOutput+CustomDebugStringConvertible.swift")
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce("mapWithSensitiveTargetedByBoth: \\\"CONTENT_REDACTED\\\"")
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(
            listOf(smithyFile),
            serviceShapeId,
            MockHTTPRestJsonProtocolGenerator(),
            { model -> model.defaultSettings(serviceShapeId, "RestJson", "2019-12-16", "Rest Json Protocol") },
            listOf(DefaultClientConfigurationIntegration())
        )

        context.generator.initializeMiddleware(context.generationCtx)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
