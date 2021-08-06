
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import java.util.Optional

class HttpQueryItemMiddlewareGeneratorTests {
    @Test
    fun `001 it creates query item middleware with idempotency token trait for httpQuery`() {
        val context = setupTests("http-binding-protocol-generator-test.smithy", "com.test#Example")
        val contents =
            getModelFileContents("example", "QueryIdempotencyTokenAutoFillInput+QueryItemMiddleware.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct QueryIdempotencyTokenAutoFillInputQueryItemMiddleware: ClientRuntime.Middleware {
                public let id: Swift.String = "QueryIdempotencyTokenAutoFillInputQueryItemMiddleware"
            
                public init() {}
            
                public func handle<H>(context: ClientRuntime.Context,
                              input: ClientRuntime.SerializeStepInput<QueryIdempotencyTokenAutoFillInput>,
                              next: H) -> Swift.Result<ClientRuntime.OperationOutput<QueryIdempotencyTokenAutoFillOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let token = input.operationInput.token {
                        let tokenQueryItem = ClientRuntime.URLQueryItem(name: "token".urlPercentEncoding(), value: Swift.String(token).urlPercentEncoding())
                        input.builder.withQueryItem(tokenQueryItem)
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = ClientRuntime.SerializeStepInput<QueryIdempotencyTokenAutoFillInput>
                public typealias MOutput = ClientRuntime.OperationOutput<QueryIdempotencyTokenAutoFillOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
                public typealias MError = ClientRuntime.SdkError<QueryIdempotencyTokenAutoFillOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 it creates query item middleware for timestamps with format`() {
        val context = setupTests("http-binding-protocol-generator-test.smithy", "com.test#Example")
        val contents = getModelFileContents("example", "TimestampInputInput+QueryItemMiddleware.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct TimestampInputInputQueryItemMiddleware: ClientRuntime.Middleware {
                public let id: Swift.String = "TimestampInputInputQueryItemMiddleware"
            
                public init() {}
            
                public func handle<H>(context: ClientRuntime.Context,
                              input: ClientRuntime.SerializeStepInput<TimestampInputInput>,
                              next: H) -> Swift.Result<ClientRuntime.OperationOutput<TimestampInputOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let queryTimestamp = input.operationInput.queryTimestamp {
                        let queryTimestampQueryItem = ClientRuntime.URLQueryItem(name: "qtime".urlPercentEncoding(), value: Swift.String(queryTimestamp.iso8601WithoutFractionalSeconds()).urlPercentEncoding())
                        input.builder.withQueryItem(queryTimestampQueryItem)
                    }
                    if let queryTimestampList = input.operationInput.queryTimestampList {
                        queryTimestampList.forEach { queryItemValue in
                            let queryItem = ClientRuntime.URLQueryItem(name: "qtimeList".urlPercentEncoding(), value: Swift.String(queryItemValue.iso8601WithoutFractionalSeconds()).urlPercentEncoding())
                            input.builder.withQueryItem(queryItem)
                        }
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = ClientRuntime.SerializeStepInput<TimestampInputInput>
                public typealias MOutput = ClientRuntime.OperationOutput<TimestampInputOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
                public typealias MError = ClientRuntime.SdkError<TimestampInputOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 it creates query item middleware smoke test`() {
        val context = setupTests("http-binding-protocol-generator-test.smithy", "com.test#Example")
        val contents = getModelFileContents("example", "SmokeTestInput+QueryItemMiddleware.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct SmokeTestInputQueryItemMiddleware: ClientRuntime.Middleware {
                public let id: Swift.String = "SmokeTestInputQueryItemMiddleware"
            
                public init() {}
            
                public func handle<H>(context: ClientRuntime.Context,
                              input: ClientRuntime.SerializeStepInput<SmokeTestInput>,
                              next: H) -> Swift.Result<ClientRuntime.OperationOutput<SmokeTestOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let query1 = input.operationInput.query1 {
                        let query1QueryItem = ClientRuntime.URLQueryItem(name: "Query1".urlPercentEncoding(), value: Swift.String(query1).urlPercentEncoding())
                        input.builder.withQueryItem(query1QueryItem)
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = ClientRuntime.SerializeStepInput<SmokeTestInput>
                public typealias MOutput = ClientRuntime.OperationOutput<SmokeTestOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
                public typealias MError = ClientRuntime.SdkError<SmokeTestOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 httpQueryParams only should not have BodyMiddleware extension`() {
        val context = setupTests("http-query-params-stringmap.smithy", "com.test#Example")
        Assertions.assertEquals(
            Optional.empty<String>(),
            context.manifest.getFileString("/example/models/AllQueryStringTypesInput+BodyMiddleware.swift")
        )
    }

    @Test
    fun `005 httpQueryParams on StringMap`() {
        val context = setupTests("http-query-params-stringmap.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/example/models/AllQueryStringTypesInput+QueryItemMiddleware.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct AllQueryStringTypesInputQueryItemMiddleware: ClientRuntime.Middleware {
                public let id: Swift.String = "AllQueryStringTypesInputQueryItemMiddleware"
            
                public init() {}
            
                public func handle<H>(context: ClientRuntime.Context,
                              input: ClientRuntime.SerializeStepInput<AllQueryStringTypesInput>,
                              next: H) -> Swift.Result<ClientRuntime.OperationOutput<AllQueryStringTypesOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let queryStringList = input.operationInput.queryStringList {
                        queryStringList.forEach { queryItemValue in
                            let queryItem = ClientRuntime.URLQueryItem(name: "StringList".urlPercentEncoding(), value: Swift.String(queryItemValue).urlPercentEncoding())
                            input.builder.withQueryItem(queryItem)
                        }
                    }
                    if let queryString = input.operationInput.queryString {
                        let queryStringQueryItem = ClientRuntime.URLQueryItem(name: "String".urlPercentEncoding(), value: Swift.String(queryString).urlPercentEncoding())
                        input.builder.withQueryItem(queryStringQueryItem)
                    }
                    if let queryParamsMapOfStrings = input.operationInput.queryParamsMapOfStrings {
                        let currentQueryItemNames = input.builder.currentQueryItems.map({${'$'}0.name})
                        queryParamsMapOfStrings.forEach { key0, value0 in
                            if !currentQueryItemNames.contains(key0) {
                                let queryItem = ClientRuntime.URLQueryItem(name: key0.urlPercentEncoding(), value: value0.urlPercentEncoding())
                                input.builder.withQueryItem(queryItem)
                            }
                        }
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = ClientRuntime.SerializeStepInput<AllQueryStringTypesInput>
                public typealias MOutput = ClientRuntime.OperationOutput<AllQueryStringTypesOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
                public typealias MError = ClientRuntime.SdkError<AllQueryStringTypesOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `006 httpQueryParams on stringListMap`() {
        val context = setupTests("http-query-params-stringlistmap.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/example/models/QueryParamsAsStringListMapInput+QueryItemMiddleware.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct QueryParamsAsStringListMapInputQueryItemMiddleware: ClientRuntime.Middleware {
                public let id: Swift.String = "QueryParamsAsStringListMapInputQueryItemMiddleware"
            
                public init() {}
            
                public func handle<H>(context: ClientRuntime.Context,
                              input: ClientRuntime.SerializeStepInput<QueryParamsAsStringListMapInput>,
                              next: H) -> Swift.Result<ClientRuntime.OperationOutput<QueryParamsAsStringListMapOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let qux = input.operationInput.qux {
                        let quxQueryItem = ClientRuntime.URLQueryItem(name: "corge".urlPercentEncoding(), value: Swift.String(qux).urlPercentEncoding())
                        input.builder.withQueryItem(quxQueryItem)
                    }
                    if let foo = input.operationInput.foo {
                        let currentQueryItemNames = input.builder.currentQueryItems.map({${'$'}0.name})
                        foo.forEach { key0, value0 in
                            if !currentQueryItemNames.contains(key0) {
                                value0.forEach { value1 in
                                    let queryItem = ClientRuntime.URLQueryItem(name: key0.urlPercentEncoding(), value: value1.urlPercentEncoding())
                                    input.builder.withQueryItem(queryItem)
                                }
                            }
                        }
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = ClientRuntime.SerializeStepInput<QueryParamsAsStringListMapInput>
                public typealias MOutput = ClientRuntime.OperationOutput<QueryParamsAsStringListMapOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
                public typealias MError = ClientRuntime.SdkError<QueryParamsAsStringListMapOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `007 query precedence with httpQuery and httpQueryParams`() {
        val context = setupTests("http-query-params-precedence.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/example/models/QueryPrecedenceInput+QueryItemMiddleware.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct QueryPrecedenceInputQueryItemMiddleware: ClientRuntime.Middleware {
                public let id: Swift.String = "QueryPrecedenceInputQueryItemMiddleware"
            
                public init() {}
            
                public func handle<H>(context: ClientRuntime.Context,
                              input: ClientRuntime.SerializeStepInput<QueryPrecedenceInput>,
                              next: H) -> Swift.Result<ClientRuntime.OperationOutput<QueryPrecedenceOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let foo = input.operationInput.foo {
                        let fooQueryItem = ClientRuntime.URLQueryItem(name: "bar".urlPercentEncoding(), value: Swift.String(foo).urlPercentEncoding())
                        input.builder.withQueryItem(fooQueryItem)
                    }
                    if let baz = input.operationInput.baz {
                        let currentQueryItemNames = input.builder.currentQueryItems.map({${'$'}0.name})
                        baz.forEach { key0, value0 in
                            if !currentQueryItemNames.contains(key0) {
                                let queryItem = ClientRuntime.URLQueryItem(name: key0.urlPercentEncoding(), value: value0.urlPercentEncoding())
                                input.builder.withQueryItem(queryItem)
                            }
                        }
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = ClientRuntime.SerializeStepInput<QueryPrecedenceInput>
                public typealias MOutput = ClientRuntime.OperationOutput<QueryPrecedenceOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
                public typealias MError = ClientRuntime.SdkError<QueryPrecedenceOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId)
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateDeserializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
