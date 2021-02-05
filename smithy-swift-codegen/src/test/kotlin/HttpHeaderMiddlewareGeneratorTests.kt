import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.AddOperationShapes
import software.amazon.smithy.swift.codegen.SwiftWriter
import io.kotest.matchers.string.shouldContainOnlyOnce
import software.amazon.smithy.swift.codegen.integration.ClientProperty
import software.amazon.smithy.swift.codegen.integration.CodingKeysGenerator
import software.amazon.smithy.swift.codegen.integration.DefaultCodingKeysGenerator
import software.amazon.smithy.swift.codegen.integration.DefaultConfig
import software.amazon.smithy.swift.codegen.integration.DefaultRequestEncoder
import software.amazon.smithy.swift.codegen.integration.DefaultResponseDecoder
import software.amazon.smithy.swift.codegen.integration.ErrorFromHttpResponseGenerator
import software.amazon.smithy.swift.codegen.integration.HttpBindingProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.HttpProtocolClientGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolClientGeneratorFactory
import software.amazon.smithy.swift.codegen.integration.HttpProtocolTestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestErrorGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestRequestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestResponseGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.ServiceConfig
import kotlin.math.exp

class HttpHeaderMiddlewareGeneratorTests {
    private var model = javaClass.getResource("http-binding-protocol-generator-test.smithy").asSmithy()
    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        return model.newTestContext()
    }
    val newTestContext = newTestContext()
    init {
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
                public var id: String = "SmokeTestInputHeaders"
            
                public func handle<H>(context: Context,
                              input: SdkHttpRequestBuilder,
                              next: H) -> Result<SdkHttpRequestBuilder, Error>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context
                {
                    if let header1 = header1 {
                        input.withHeader(name: "X-Header1", value: String(header1))
                    }
                    if let header2 = header2 {
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
            public var id: String = "EnumInputInputHeaders"
        
            public func handle<H>(context: Context,
                          input: SdkHttpRequestBuilder,
                          next: H) -> Result<SdkHttpRequestBuilder, Error>
            where H: Handler,
            Self.MInput == H.Input,
            Self.MOutput == H.Output,
            Self.Context == H.Context
            {
                if let enumHeader = enumHeader {
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
            public var id: String = "IdempotencyTokenWithoutHttpPayloadTraitOnTokenInputHeaders"
        
            public func handle<H>(context: Context,
                          input: SdkHttpRequestBuilder,
                          next: H) -> Result<SdkHttpRequestBuilder, Error>
            where H: Handler,
            Self.MInput == H.Input,
            Self.MOutput == H.Output,
            Self.Context == H.Context
            {
                if let token = token {
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
            public var id: String = "TimestampInputInputHeaders"
        
            public func handle<H>(context: Context,
                          input: SdkHttpRequestBuilder,
                          next: H) -> Result<SdkHttpRequestBuilder, Error>
            where H: Handler,
            Self.MInput == H.Input,
            Self.MOutput == H.Output,
            Self.Context == H.Context
            {
                if let headerEpoch = headerEpoch {
                    input.withHeader(name: "X-Epoch", value: String(headerEpoch.timeIntervalSince1970.clean))
                }
                if let headerHttpDate = headerHttpDate {
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
}