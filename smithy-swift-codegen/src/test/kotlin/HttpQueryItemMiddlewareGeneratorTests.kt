import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.AddOperationShapes

class HttpQueryItemMiddlewareGeneratorTests {
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
    fun `it creates query item middleware with idempotency token trait for httpQuery`() {
        val contents =
            getModelFileContents("example", "QueryIdempotencyTokenAutoFillInput+QueryItemMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct QueryIdempotencyTokenAutoFillInputQueryItemMiddleware: Middleware {
                public let id: String = "QueryIdempotencyTokenAutoFillInputQueryItemMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: SerializeStepInput<QueryIdempotencyTokenAutoFillInput>,
                              next: H) -> Swift.Result<OperationOutput<QueryIdempotencyTokenAutoFillOutput, QueryIdempotencyTokenAutoFillOutputError>, Error>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context
                {
                    if let token = input.operationInput.token {
                        let tokenQueryItem = URLQueryItem(name: "token", value: String(token))
                        input.builder.withQueryItem(tokenQueryItem)
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SerializeStepInput<QueryIdempotencyTokenAutoFillInput>
                public typealias MOutput = OperationOutput<QueryIdempotencyTokenAutoFillOutput, QueryIdempotencyTokenAutoFillOutputError>
                public typealias Context = HttpContext
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates query item middleware for timestamps with format`() {
        val contents = getModelFileContents("example", "TimestampInputInput+QueryItemMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct TimestampInputInputQueryItemMiddleware: Middleware {
                public let id: String = "TimestampInputInputQueryItemMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: SerializeStepInput<TimestampInputInput>,
                              next: H) -> Swift.Result<OperationOutput<TimestampInputOutput, TimestampInputOutputError>, Error>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context
                {
                    if let queryTimestamp = input.operationInput.queryTimestamp {
                        let queryTimestampQueryItem = URLQueryItem(name: "qtime", value: String(queryTimestamp.iso8601WithoutFractionalSeconds()))
                        input.builder.withQueryItem(queryTimestampQueryItem)
                    }
                    if let queryTimestampList = input.operationInput.queryTimestampList {
                        queryTimestampList.forEach { queryItemValue in
                            let queryItem = URLQueryItem(name: "qtimeList", value: String(queryItemValue.iso8601WithoutFractionalSeconds()))
                            input.builder.withQueryItem(queryItem)
                        }
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SerializeStepInput<TimestampInputInput>
                public typealias MOutput = OperationOutput<TimestampInputOutput, TimestampInputOutputError>
                public typealias Context = HttpContext
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates query item middleware smoke test`() {
        val contents = getModelFileContents("example", "SmokeTestInput+QueryItemMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct SmokeTestInputQueryItemMiddleware: Middleware {
                public let id: String = "SmokeTestInputQueryItemMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: SerializeStepInput<SmokeTestInput>,
                              next: H) -> Swift.Result<OperationOutput<SmokeTestOutput, SmokeTestOutputError>, Error>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context
                {
                    if let query1 = input.operationInput.query1 {
                        let query1QueryItem = URLQueryItem(name: "Query1", value: String(query1))
                        input.builder.withQueryItem(query1QueryItem)
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SerializeStepInput<SmokeTestInput>
                public typealias MOutput = OperationOutput<SmokeTestOutput, SmokeTestOutputError>
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
