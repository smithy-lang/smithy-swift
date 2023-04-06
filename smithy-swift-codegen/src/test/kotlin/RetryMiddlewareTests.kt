import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class RetryMiddlewareTests {

    @Test
    fun `generates operation with retry middleware`() {
        val context = setupTests("Isolated/contentmd5checksum.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/RestXmlProtocolClient.swift")
        val expectedContents = """
        let retryStrategy = try config.retryOptions.retryStrategy ?? DefaultRetryStrategy(retryStrategyOptions: RetryStrategyOptions(retryMode: config.retryOptions.retryMode, maxRetriesBase: config.retryOptions.maxAttempts))
        let retryErrorClassifier = config.retryOptions.retryErrorClassifier ?? DefaultRetryErrorClassifier()
        operation.finalizeStep.intercept(position: .after, middleware: ClientRuntime.RetryerMiddleware<IdempotencyTokenWithStructureOutputResponse, IdempotencyTokenWithStructureOutputError>(retryStrategy: retryStrategy, retryErrorClassifier: retryErrorClassifier))
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.initializeMiddleware(context.generationCtx)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
