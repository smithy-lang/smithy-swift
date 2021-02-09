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
                              input: SerializeInput<QueryIdempotencyTokenAutoFillInput>,
                              next: H) -> Result<SerializeInput<QueryIdempotencyTokenAutoFillInput>, Error>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context
                {
                    if let token = input.operationInput.token {
                        let queryItem = URLQueryItem(name: "token", value: String(token))
                        input.builder.withQueryItem(queryItem)
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SerializeInput<QueryIdempotencyTokenAutoFillInput>
                public typealias MOutput = SerializeInput<QueryIdempotencyTokenAutoFillInput>
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
                              input: SerializeInput<TimestampInputInput>,
                              next: H) -> Result<SerializeInput<TimestampInputInput>, Error>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context
                {
                    if let queryTimestamp = input.operationInput.queryTimestamp {
                        let queryItem = URLQueryItem(name: "qtime", value: String(queryTimestamp.iso8601WithoutFractionalSeconds()))
                        input.builder.withQueryItem(queryItem)
                    }
                    if let queryTimestampList = input.operationInput.queryTimestampList {
                        queryTimestampList.forEach { queryItemValue in
                            let queryItem = URLQueryItem(name: "qtimeList", value: String(queryItemValue.iso8601WithoutFractionalSeconds()))
                            input.builder.withQueryItem(queryItem)
                        }
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SerializeInput<TimestampInputInput>
                public typealias MOutput = SerializeInput<TimestampInputInput>
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
                              input: SerializeInput<SmokeTestInput>,
                              next: H) -> Result<SerializeInput<SmokeTestInput>, Error>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context
                {
                    if let query1 = input.operationInput.query1 {
                        let queryItem = URLQueryItem(name: "Query1", value: String(query1))
                        input.builder.withQueryItem(queryItem)
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = SerializeInput<SmokeTestInput>
                public typealias MOutput = SerializeInput<SmokeTestInput>
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
