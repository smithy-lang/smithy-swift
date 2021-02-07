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
        newTestContext.generationCtx.delegator.flushWriters()
    }

    @Test
    fun `it creates smoke test request builder`() {
        val contents = getModelFileContents("example", "SmokeTestInput+HeaderMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct SmokeTestInputHeadersMiddleware: Middleware {
                public let id: String = "SmokeTestInputHeadersMiddleware"
            
                let smokeTestInput: SmokeTestInput
            
                public func handle<H>(context: Context,
                              input: SdkHttpRequestBuilder,
                              next: H) -> Result<SdkHttpRequestBuilder, Error>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context
                {
                    if let header1 = smokeTestInput.header1 {
                        input.withHeader(name: "X-Header1", value: String(header1))
                    }
                    if let header2 = smokeTestInput.header2 {
                        input.withHeader(name: "X-Header2", value: String(header2))
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SdkHttpRequestBuilder
                public typealias MOutput = SdkHttpRequestBuilder
                public typealias Context = HttpContext
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds headers with enums as raw values`() {
        val contents = getModelFileContents("example", "EnumInputInput+HeaderMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct EnumInputInputHeadersMiddleware: Middleware {
                public let id: String = "EnumInputInputHeadersMiddleware"
            
                let enumInputInput: EnumInputInput
            
                public func handle<H>(context: Context,
                              input: SdkHttpRequestBuilder,
                              next: H) -> Result<SdkHttpRequestBuilder, Error>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context
                {
                    if let enumHeader = enumInputInput.enumHeader {
                        input.withHeader(name: "X-EnumHeader", value: String(enumHeader.rawValue))
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SdkHttpRequestBuilder
                public typealias MOutput = SdkHttpRequestBuilder
                public typealias Context = HttpContext
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds header with idempotency token value`() {
        val contents = getModelFileContents(
            "example",
            "IdempotencyTokenWithoutHttpPayloadTraitOnTokenInput+HeaderMiddleware.swift",
            newTestContext.manifest
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct IdempotencyTokenWithoutHttpPayloadTraitOnTokenInputHeadersMiddleware: Middleware {
                public let id: String = "IdempotencyTokenWithoutHttpPayloadTraitOnTokenInputHeadersMiddleware"
            
                let idempotencyTokenWithoutHttpPayloadTraitOnTokenInput: IdempotencyTokenWithoutHttpPayloadTraitOnTokenInput
            
                public func handle<H>(context: Context,
                              input: SdkHttpRequestBuilder,
                              next: H) -> Result<SdkHttpRequestBuilder, Error>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context
                {
                    if let token = idempotencyTokenWithoutHttpPayloadTraitOnTokenInput.token {
                        input.withHeader(name: "token", value: String(token))
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SdkHttpRequestBuilder
                public typealias MOutput = SdkHttpRequestBuilder
                public typealias Context = HttpContext
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates http headers for timestamps with format`() {
        val contents =
            getModelFileContents("example", "TimestampInputInput+HeaderMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct TimestampInputInputHeadersMiddleware: Middleware {
                public let id: String = "TimestampInputInputHeadersMiddleware"
            
                let timestampInputInput: TimestampInputInput
            
                public func handle<H>(context: Context,
                              input: SdkHttpRequestBuilder,
                              next: H) -> Result<SdkHttpRequestBuilder, Error>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context
                {
                    if let headerEpoch = timestampInputInput.headerEpoch {
                        input.withHeader(name: "X-Epoch", value: String(headerEpoch.timeIntervalSince1970.clean))
                    }
                    if let headerHttpDate = timestampInputInput.headerHttpDate {
                        input.withHeader(name: "X-Date", value: String(headerHttpDate.rfc5322()))
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SdkHttpRequestBuilder
                public typealias MOutput = SdkHttpRequestBuilder
                public typealias Context = HttpContext
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
