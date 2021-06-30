import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.AddOperationShapes

class HttpHeaderMiddlewareGeneratorTests {
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

    @Test
    fun `it creates smoke test request builder`() {
        val contents = getModelFileContents("example", "SmokeTestInput+Extensions.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct SmokeTestInputHeadersMiddleware: Middleware {
                public let id: String = "SmokeTestInputHeadersMiddleware"
            
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
                    if let header1 = input.operationInput.header1 {
                        input.builder.withHeader(name: "X-Header1", value: String(header1))
                    }
                    if let header2 = input.operationInput.header2 {
                        input.builder.withHeader(name: "X-Header2", value: String(header2))
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
    fun `it builds headers with enums as raw values`() {
        val contents = getModelFileContents("example", "EnumInputInput+Extensions.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct EnumInputInputHeadersMiddleware: Middleware {
                public let id: String = "EnumInputInputHeadersMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: SerializeStepInput<EnumInputInput>,
                              next: H) -> Swift.Result<OperationOutput<EnumInputOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let enumHeader = input.operationInput.enumHeader {
                        input.builder.withHeader(name: "X-EnumHeader", value: String(enumHeader.rawValue))
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SerializeStepInput<EnumInputInput>
                public typealias MOutput = OperationOutput<EnumInputOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
                public typealias MError = SdkError<EnumInputOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds header with idempotency token value`() {
        val contents = getModelFileContents(
            "example",
            "IdempotencyTokenWithoutHttpPayloadTraitOnTokenInput+Extensions.swift",
            newTestContext.manifest
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct IdempotencyTokenWithoutHttpPayloadTraitOnTokenInputHeadersMiddleware: Middleware {
                public let id: String = "IdempotencyTokenWithoutHttpPayloadTraitOnTokenInputHeadersMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: SerializeStepInput<IdempotencyTokenWithoutHttpPayloadTraitOnTokenInput>,
                              next: H) -> Swift.Result<OperationOutput<IdempotencyTokenWithoutHttpPayloadTraitOnTokenOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let token = input.operationInput.token {
                        input.builder.withHeader(name: "token", value: String(token))
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SerializeStepInput<IdempotencyTokenWithoutHttpPayloadTraitOnTokenInput>
                public typealias MOutput = OperationOutput<IdempotencyTokenWithoutHttpPayloadTraitOnTokenOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
                public typealias MError = SdkError<IdempotencyTokenWithoutHttpPayloadTraitOnTokenOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates http headers for timestamps with format`() {
        val contents =
            getModelFileContents("example", "TimestampInputInput+Extensions.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct TimestampInputInputHeadersMiddleware: Middleware {
                public let id: String = "TimestampInputInputHeadersMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: SerializeStepInput<TimestampInputInput>,
                              next: H) -> Swift.Result<OperationOutput<TimestampInputOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let headerEpoch = input.operationInput.headerEpoch {
                        input.builder.withHeader(name: "X-Epoch", value: String(headerEpoch.timeIntervalSince1970.clean))
                    }
                    if let headerHttpDate = input.operationInput.headerHttpDate {
                        input.builder.withHeader(name: "X-Date", value: String(headerHttpDate.rfc5322()))
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SerializeStepInput<TimestampInputInput>
                public typealias MOutput = OperationOutput<TimestampInputOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
                public typealias MError = SdkError<TimestampInputOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        return model.newTestContext()
    }
}
