
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.model.AddOperationShapes

class HttpUrlPathMiddlewareTests {
    @Test
    fun `it builds url path middleware smoke test`() {
        val context = setupTests("http-binding-protocol-generator-test.smithy")
        val contents = getModelFileContents("example", "SmokeTestInput+UrlPathMiddleware.swift", context.manifest)
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
                    let hostCustomPath = context.getHost().substringAfterEmpty("/")
                    var urlPath = "/smoketest/\(label1.urlPercentEncoding())/foo"
                    if !hostCustomPath.isEmpty {
                        urlPath = "/\(hostCustomPath)\(urlPath)"
                    }
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
