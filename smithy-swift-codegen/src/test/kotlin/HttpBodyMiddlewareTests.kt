import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.model.AddOperationShapes

class HttpBodyMiddlewareTests {
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
    fun `it builds body middleware smoke test`() {
        val contents = getModelFileContents("example", "SmokeTestInput+BodyMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct SmokeTestInputBodyMiddleware: Middleware {
                public let id: String = "SmokeTestInputBodyMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: SerializeStepInput<SmokeTestInput>,
                              next: H) -> Swift.Result<OperationOutput<SmokeTestOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    do {
                        if try !input.operationInput.allPropertiesAreNull() {
                            let encoder = context.getEncoder()
                            let data = try encoder.encode(input.operationInput)
                            let body = HttpBody.data(data)
                            input.builder.withBody(body)
                        }
                    } catch let err {
                        return .failure(.client(ClientError.serializationFailed(err.localizedDescription)))
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SerializeStepInput<SmokeTestInput>
                public typealias MOutput = OperationOutput<SmokeTestOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
                public typealias MError = SdkError<SmokeTestOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds body middleware for explicit string payloads`() {
        val contents = getModelFileContents("example", "ExplicitStringInput+BodyMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct ExplicitStringInputBodyMiddleware: Middleware {
                public let id: String = "ExplicitStringInputBodyMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: SerializeStepInput<ExplicitStringInput>,
                              next: H) -> Swift.Result<OperationOutput<ExplicitStringOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let payload1 = input.operationInput.payload1 {
                        let payload1data = payload1.data(using: .utf8)
                        let payload1body = HttpBody.data(payload1data)
                        input.builder.withBody(payload1body)
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SerializeStepInput<ExplicitStringInput>
                public typealias MOutput = OperationOutput<ExplicitStringOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
                public typealias MError = SdkError<ExplicitStringOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds body middleware for explicit blob payloads`() {
        val contents = getModelFileContents("example", "ExplicitBlobInput+BodyMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct ExplicitBlobInputBodyMiddleware: Middleware {
                public let id: String = "ExplicitBlobInputBodyMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: SerializeStepInput<ExplicitBlobInput>,
                              next: H) -> Swift.Result<OperationOutput<ExplicitBlobOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let payload1 = input.operationInput.payload1 {
                        let payload1data = payload1
                        let payload1body = HttpBody.data(payload1data)
                        input.builder.withBody(payload1body)
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SerializeStepInput<ExplicitBlobInput>
                public typealias MOutput = OperationOutput<ExplicitBlobOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
                public typealias MError = SdkError<ExplicitBlobOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds body middleware for explicit streaming blob payloads`() {
        val contents = getModelFileContents("example", "ExplicitBlobStreamInput+BodyMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct ExplicitBlobStreamInputBodyMiddleware: Middleware {
                public let id: String = "ExplicitBlobStreamInputBodyMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: SerializeStepInput<ExplicitBlobStreamInput>,
                              next: H) -> Swift.Result<OperationOutput<ExplicitBlobStreamOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let payload1 = input.operationInput.payload1 {
                        let payload1data = payload1
                        let payload1body = HttpBody.stream(payload1data)
                        input.builder.withBody(payload1body)
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SerializeStepInput<ExplicitBlobStreamInput>
                public typealias MOutput = OperationOutput<ExplicitBlobStreamOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
                public typealias MError = SdkError<ExplicitBlobStreamOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds body middleware for explicit struct payloads`() {
        val contents = getModelFileContents("example", "ExplicitStructInput+BodyMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct ExplicitStructInputBodyMiddleware: Middleware {
                public let id: String = "ExplicitStructInputBodyMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: SerializeStepInput<ExplicitStructInput>,
                              next: H) -> Swift.Result<OperationOutput<ExplicitStructOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let payload1 = input.operationInput.payload1 {
                        do {
                            let encoder = context.getEncoder()
                            let payload1data = try encoder.encode(payload1)
                            let payload1body = HttpBody.data(payload1data)
                            input.builder.withBody(payload1body)
                        } catch let err {
                            return .failure(.client(ClientError.serializationFailed(err.localizedDescription)))
                        }
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SerializeStepInput<ExplicitStructInput>
                public typealias MOutput = OperationOutput<ExplicitStructOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
                public typealias MError = SdkError<ExplicitStructOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
