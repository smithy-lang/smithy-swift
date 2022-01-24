
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
            public struct SmokeTestInputURLPathMiddleware: Runtime.Middleware {
                public let id: Swift.String = "SmokeTestInputURLPathMiddleware"
            
                let urlPrefix: Swift.String?
            
                public init(urlPrefix: Swift.String? = nil) {
                    self.urlPrefix = urlPrefix
                }
            
                public func handle<H>(context: Context,
                              input: SmokeTestInput,
                              next: H) -> Swift.Result<Runtime.OperationOutput<SmokeTestOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    guard let label1 = input.label1 else {
                        return .failure(.client(Runtime.ClientError.pathCreationFailed(("label1 is nil and needs a value for the path of this operation"))))
                    }
                    var urlPath = "/smoketest/\(label1.urlPercentEncoding())/foo"
                    if let urlPrefix = urlPrefix, !urlPrefix.isEmpty {
                        urlPath = "\(urlPrefix)\(urlPath)"
                    }
                    var copiedContext = context
                    copiedContext.attributes.set(key: AttributeKey<String>(name: "Path"), value: urlPath)
                    return next.handle(context: copiedContext, input: input)
                }
            
                public typealias MInput = SmokeTestInput
                public typealias MOutput = Runtime.OperationOutput<SmokeTestOutputResponse>
                public typealias Context = Runtime.HttpContext
                public typealias MError = Runtime.SdkError<SmokeTestOutputError>
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
