import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.model.AddOperationShapes

class HttpUrlPathMiddlewareTests {
    private var model = javaClass.getResource("http-binding-protocol-generator-test.smithy").asSmithy()
    var newTestContext: TestContext
    init {
        newTestContext = newTestContext()
        newTestContext.generator.generateSerializers(newTestContext.generationCtx)
        newTestContext.generator.generateProtocolClient(newTestContext.generationCtx)
        newTestContext.generator.generateDeserializers(newTestContext.generationCtx)
        newTestContext.generator.generateCodableConformanceForNestedTypes(newTestContext.generationCtx)
        newTestContext.generationCtx.delegator.flushWriters()
    }
    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        return model.newTestContext()
    }

    @Test
    fun `it builds url path middleware smoke test`() {
        val contents = getModelFileContents("example", "SmokeTestInput+UrlPathMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct SmokeTestInputURLPathMiddleware: ClientRuntime.Middleware {
                public let id: Swift.String = "SmokeTestInputURLPathMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: SmokeTestInput,
                              next: H) -> Swift.Result<ClientRuntime.OperationOutput<SmokeTestOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    guard let label1 = input.label1 else {
                        return .failure(.client(ClientRuntime.ClientError.pathCreationFailed(("label1 is nil and needs a value for the path of this operation"))))
                    }
                    let urlPath = "/smoketest/\(label1)/foo"
                    var copiedContext = context
                    copiedContext.attributes.set(key: AttributeKey<String>(name: "Path"), value: urlPath)
                    return next.handle(context: copiedContext, input: input)
                }
            
                public typealias MInput = SmokeTestInput
                public typealias MOutput = ClientRuntime.OperationOutput<SmokeTestOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
                public typealias MError = ClientRuntime.SdkError<SmokeTestOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
