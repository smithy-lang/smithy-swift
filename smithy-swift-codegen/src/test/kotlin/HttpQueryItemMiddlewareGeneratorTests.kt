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
            public var id: String = "QueryIdempotencyTokenAutoFillInputQueryItem"
        
            public func handle<H>(context: Context,
                          input: SdkHttpRequestBuilder,
                          next: H) -> Result<SdkHttpRequestBuilder, Error>
            where H: Handler,
            Self.MInput == H.Input,
            Self.MOutput == H.Output,
            Self.Context == H.Context
            {
                if let token = token {
                    let queryItem = URLQueryItem(name: "token", value: String(token))
                    input.withQueryItem(queryItem)
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
    fun `it creates query item middleware for timestamps with format`() {
        val contents = getModelFileContents("example", "TimestampInputInput+QueryItemMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
        public struct TimestampInputInputQueryItemMiddleware: Middleware {
            public var id: String = "TimestampInputInputQueryItem"
        
            public func handle<H>(context: Context,
                          input: SdkHttpRequestBuilder,
                          next: H) -> Result<SdkHttpRequestBuilder, Error>
            where H: Handler,
            Self.MInput == H.Input,
            Self.MOutput == H.Output,
            Self.Context == H.Context
            {
                if let queryTimestamp = queryTimestamp {
                    let queryItem = URLQueryItem(name: "qtime", value: String(queryTimestamp.iso8601WithoutFractionalSeconds()))
                    input.withQueryItem(queryItem)
                }
                if let queryTimestampList = queryTimestampList {
                    queryTimestampList.forEach { queryItemValue in
                        let queryItem = URLQueryItem(name: "qtimeList", value: String(queryItemValue.iso8601WithoutFractionalSeconds()))
                        input.withQueryItem(queryItem)
                    }
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
    fun `it creates query item middleware smoke test`() {
        val contents = getModelFileContents("example", "SmokeTestInput+QueryItemMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
        public struct SmokeTestInputQueryItemMiddleware: Middleware {
            public var id: String = "SmokeTestInputQueryItem"
        
            public func handle<H>(context: Context,
                          input: SdkHttpRequestBuilder,
                          next: H) -> Result<SdkHttpRequestBuilder, Error>
            where H: Handler,
            Self.MInput == H.Input,
            Self.MOutput == H.Output,
            Self.Context == H.Context
            {
                if let query1 = query1 {
                    let queryItem = URLQueryItem(name: "Query1", value: String(query1))
                    input.withQueryItem(queryItem)
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
