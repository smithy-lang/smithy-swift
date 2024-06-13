import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class ContentMd5MiddlewareTests {
    @Test
    fun `generates ContentMD5 middleware`() {
        val context = setupTests("Isolated/contentmd5checksum.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/RestXmlProtocolClient.swift")
        val expectedContents = """
        operation.buildStep.intercept(position: .before, middleware: ClientRuntime.ContentMD5Middleware<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutput>())
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHTTPRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.initializeMiddleware(context.generationCtx)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
