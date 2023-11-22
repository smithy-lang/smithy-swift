import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class IdempotencyTokenTraitTests {
    @Test
    fun `generates idempotent middleware`() {
        val context = setupTests("Isolated/idempotencyToken.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/RestXmlProtocolClient.swift")
        val expectedContents = """
extension RestXmlProtocolClient: RestXmlProtocolClientProtocol {
    /// Performs the `IdempotencyTokenWithStructure` operation on the `RestXml` service.
    ///
    /// This is a very cool operation.
    ///
    /// - Parameter IdempotencyTokenWithStructureInput : [no documentation found]
    ///
    /// - Returns: `IdempotencyTokenWithStructureOutput` : [no documentation found]
    public func idempotencyTokenWithStructure(input: IdempotencyTokenWithStructureInput) async throws -> IdempotencyTokenWithStructureOutput
    {
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
        var operation = ClientRuntime.OperationStack<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutput, IdempotencyTokenWithStructureOutputError>(id: "idempotencyTokenWithStructure")
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.IdempotencyTokenMiddleware<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutput, IdempotencyTokenWithStructureOutputError>(keyPath: \.token))
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutput, IdempotencyTokenWithStructureOutputError>())
        operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutput>())
        operation.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutput>(contentType: "application/xml"))
        operation.serializeStep.intercept(position: .after, middleware: ClientRuntime.SerializableBodyMiddleware<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutput>(xmlName: "IdempotencyToken"))
        operation.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
        operation.finalizeStep.intercept(position: .after, middleware: ClientRuntime.RetryMiddleware<ClientRuntime.DefaultRetryStrategy, ClientRuntime.DefaultRetryErrorInfoProvider, IdempotencyTokenWithStructureOutput, IdempotencyTokenWithStructureOutputError>(options: config.retryStrategyOptions))
        operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.DeserializeMiddleware<IdempotencyTokenWithStructureOutput, IdempotencyTokenWithStructureOutputError>())
        operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.LoggerMiddleware<IdempotencyTokenWithStructureOutput, IdempotencyTokenWithStructureOutputError>(clientLogMode: config.clientLogMode))
        let result = try await operation.handleMiddleware(context: context, input: input, next: client.getHandler())
        return result
    }

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
