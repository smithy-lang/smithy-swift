import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class ContentMd5MiddlewareTests {
    @Test
    fun `generates ContentMD5 middleware`() {
        val context = setupTests("Isolated/contentmd5checksum.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/RestXmlProtocolClient.swift")
        val expectedContents =
            """
            extension RestXmlProtocolClient: RestXmlProtocolClientProtocol {
                public func idempotencyTokenWithStructure(input: IdempotencyTokenWithStructureInput, completion: @escaping (ClientRuntime.SdkResult<IdempotencyTokenWithStructureOutputResponse, IdempotencyTokenWithStructureOutputError>) -> Void)
                {
                    let context = ClientRuntime.HttpContextBuilder()
                                  .withEncoder(value: encoder)
                                  .withDecoder(value: decoder)
                                  .withMethod(value: .put)
                                  .withServiceName(value: serviceName)
                                  .withOperation(value: "idempotencyTokenWithStructure")
                                  .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
                                  .withLogger(value: config.logger)
                    var operation = ClientRuntime.OperationStack<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutputResponse, IdempotencyTokenWithStructureOutputError>(id: "idempotencyTokenWithStructure")
                    operation.initializeStep.intercept(position: .after, id: "IdempotencyTokenMiddleware") { (context, input, next) -> Swift.Result<ClientRuntime.OperationOutput<IdempotencyTokenWithStructureOutputResponse>, ClientRuntime.SdkError<IdempotencyTokenWithStructureOutputError>> in
                        let idempotencyTokenGenerator = context.getIdempotencyTokenGenerator()
                        var copiedInput = input
                        if input.token == nil {
                            copiedInput.token = idempotencyTokenGenerator.generateToken()
                        }
                        return next.handle(context: context, input: copiedInput)
                    }
                    operation.initializeStep.intercept(position: .after, middleware: IdempotencyTokenWithStructureInputURLPathMiddleware())
                    operation.initializeStep.intercept(position: .after, middleware: IdempotencyTokenWithStructureInputURLHostMiddleware())
                    operation.buildStep.intercept(position: .before, middleware: ClientRuntime.ContentMD5Middleware<IdempotencyTokenWithStructureOutputResponse, IdempotencyTokenWithStructureOutputError>())
                    operation.serializeStep.intercept(position: .after, middleware: IdempotencyTokenWithStructureInputHeadersMiddleware())
                    operation.serializeStep.intercept(position: .after, middleware: IdempotencyTokenWithStructureInputQueryItemMiddleware())
                    operation.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutputResponse, IdempotencyTokenWithStructureOutputError>(contentType: "application/xml"))
                    operation.serializeStep.intercept(position: .after, middleware: IdempotencyTokenWithStructureInputBodyMiddleware())
                    operation.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
                    operation.deserializeStep.intercept(position: .before, middleware: ClientRuntime.LoggerMiddleware(clientLogMode: config.clientLogMode))
                    operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.DeserializeMiddleware())
                    let result = operation.handleMiddleware(context: context.build(), input: input, next: client.getHandler())
                    completion(result)
                }
            """.trimIndent()
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
