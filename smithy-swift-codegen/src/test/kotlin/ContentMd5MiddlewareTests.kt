import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class ContentMd5MiddlewareTests {
    @Test
    fun `generates ContentMD5 middleware`() {
        val context = setupTests("Isolated/contentmd5checksum.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/RestXmlProtocolClient.swift")
        val expectedContents = """
    public func idempotencyTokenWithStructure(input: IdempotencyTokenWithStructureInput) async throws -> IdempotencyTokenWithStructureOutput {
        let context = ClientRuntime.HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .withDecoder(value: decoder)
                      .withMethod(value: .put)
                      .withServiceName(value: serviceName)
                      .withOperation(value: "idempotencyTokenWithStructure")
                      .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
                      .withLogger(value: config.logger)
                      .withPartitionID(value: config.partitionID)
                      .build()
        var operation = ClientRuntime.OperationStack<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutput>(id: "idempotencyTokenWithStructure")
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.IdempotencyTokenMiddleware<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutput>(keyPath: \.token))
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutput>(IdempotencyTokenWithStructureInput.urlPathProvider(_:)))
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutput>())
        operation.buildStep.intercept(position: .before, middleware: ClientRuntime.ContentMD5Middleware<IdempotencyTokenWithStructureOutput>())
        operation.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutput>(contentType: "application/xml"))
        operation.serializeStep.intercept(position: .after, middleware: ClientRuntime.BodyMiddleware<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutput, SmithyXML.Writer>(documentWritingClosure: SmithyXML.XMLReadWrite.documentWritingClosure(rootNodeInfo: .init("IdempotencyToken")), inputWritingClosure: IdempotencyTokenWithStructureInput.writingClosure(_:to:)))
        operation.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
        operation.finalizeStep.intercept(position: .after, middleware: ClientRuntime.RetryMiddleware<ClientRuntime.DefaultRetryStrategy, ClientRuntime.DefaultRetryErrorInfoProvider, IdempotencyTokenWithStructureOutput>(options: config.retryStrategyOptions))
        operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.DeserializeMiddleware<IdempotencyTokenWithStructureOutput>(responseClosure(decoder: decoder), responseErrorClosure(IdempotencyTokenWithStructureOutputError.self, decoder: decoder)))
        operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.LoggerMiddleware<IdempotencyTokenWithStructureOutput>(clientLogMode: config.clientLogMode))
        let result = try await operation.handleMiddleware(context: context, input: input, next: client.getHandler())
        return result
    }
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
