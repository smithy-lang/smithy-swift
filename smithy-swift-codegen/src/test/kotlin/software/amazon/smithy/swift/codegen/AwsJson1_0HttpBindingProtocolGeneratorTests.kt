package software.amazon.smithy.swift.codegen

import software.amazon.smithy.aws.traits.protocols.AwsJson1_0Trait
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.integration.HttpBindingProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolTestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestErrorGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestRequestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestResponseGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class AwsJson1_0MockHttpProtocolGenerator : HttpBindingProtocolGenerator() {
    override val defaultContentType: String = "application/x-amz-json-1.0"
    override val defaultTimestampFormat: TimestampFormatTrait.Format = TimestampFormatTrait.Format.DATE_TIME
    override val protocol: ShapeId = AwsJson1_0Trait.ID

    override fun generateProtocolUnitTests(ctx: ProtocolGenerator.GenerationContext) {

        val requestTestBuilder = HttpProtocolUnitTestRequestGenerator.Builder()
        val responseTestBuilder = HttpProtocolUnitTestResponseGenerator.Builder()
        val errorTestBuilder = HttpProtocolUnitTestErrorGenerator.Builder()

        HttpProtocolTestGenerator(
                ctx,
                requestTestBuilder,
                responseTestBuilder,
                errorTestBuilder
        ).generateProtocolTests()
    }
}

// NOTE: protocol conformance is mostly handled by the protocol tests suite
class AwsJson1_0HttpBindingProtocolGeneratorTests : TestsBase() {
    var model = createModelFromSmithy("awsJson1_0.smithy")

    data class TestContext(val ctx: ProtocolGenerator.GenerationContext, val manifest: MockManifest, val generator: AwsJson1_0MockHttpProtocolGenerator)

    private fun newTestContext(): TestContext {
        val manifest = MockManifest()
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "Example")
        val serviceShapeIdWithNamespace = "com.test#Example"
        val service = model.getShape(ShapeId.from(serviceShapeIdWithNamespace)).get().asServiceShape().get()
        val settings = SwiftSettings.from(model, buildDefaultSwiftSettingsObjectNode(serviceShapeIdWithNamespace))
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        val delegator = SwiftDelegator(settings, model, manifest, provider)
        val generator = AwsJson1_0MockHttpProtocolGenerator()
        val ctx = ProtocolGenerator.GenerationContext(settings, model, service, provider, listOf(), generator.protocol, delegator)
        return TestContext(ctx, manifest, generator)
    }

    val newTestContext = newTestContext()

    init {
        newTestContext.generator.generateSerializers(newTestContext.ctx)
        newTestContext.generator.generateProtocolClient(newTestContext.ctx)
        newTestContext.generator.generateDeserializers(newTestContext.ctx)
        newTestContext.ctx.delegator.flushWriters()
    }

//    @Test
//    fun `it builds request binding for EmptyInputAndEmptyOutput`() {
//        val contents = getModelFileContents("example", "EmptyInputAndEmptyOutputInput+HttpRequestBinding.swift", newTestContext.manifest)
//        contents.shouldSyntacticSanityCheck()
//        val expectedContents =
//                """
//                extension EmptyInputAndEmptyOutputInput: HttpRequestBinding, Reflection {
//                    public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequest {
//                        var queryItems: [URLQueryItem] = [URLQueryItem]()
//                        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
//                        var headers = Headers()
//                        headers.add(name: "X-Amz-Target", value: "JsonRpc10.EmptyInputAndEmptyOutput")
//                        headers.add(name: "Content-Type", value: "application/x-amz-json-1.0")
//                        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers)
//                    }
//                }
//                """.trimIndent()
//        contents.shouldContainOnlyOnce(expectedContents)
//    }

//    @Test
//    fun `it builds request binding for GreetingWithErrors`() {
//        val contents = getModelFileContents("example", "GreetingWithErrorsInput+HttpRequestBinding.swift", newTestContext.manifest)
//        contents.shouldSyntacticSanityCheck()
//        val expectedContents =
//                """
//                extension GreetingWithErrorsInput: HttpRequestBinding, Reflection {
//                    public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequest {
//                        var queryItems: [URLQueryItem] = [URLQueryItem]()
//                        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
//                        var headers = Headers()
//                        headers.add(name: "X-Amz-Target", value: "JsonRpc10.GreetingWithErrors")
//                        headers.add(name: "Content-Type", value: "application/x-amz-json-1.0")
//                        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers)
//                    }
//                }
//                """.trimIndent()
//        contents.shouldContainOnlyOnce(expectedContents)
//    }

//    @Test
//    fun `it builds response binding for EmptyInputAndEmptyOutput output`() {
//        val contents = getModelFileContents("example", "EmptyInputAndEmptyOutputOutput+ResponseInit.swift", newTestContext.manifest)
//        contents.shouldSyntacticSanityCheck()
//        val expectedContents =
//                """
//                extension EmptyInputAndEmptyOutputOutput: HttpResponseBinding {
//                    public init (httpResponse: HttpResponse, decoder: ResponseDecoder? = nil) throws {
//
//                    }
//                }
//                """.trimIndent()
//        contents.shouldContainOnlyOnce(expectedContents)
//    }
//
//    @Test
//    fun `it builds response binding for GreetingWithErrors output`() {
//        val contents = getModelFileContents("example", "GreetingWithErrorsOutput+ResponseInit.swift", newTestContext.manifest)
//        contents.shouldSyntacticSanityCheck()
//        val expectedContents =
//                """
//                extension GreetingWithErrorsOutput: HttpResponseBinding {
//                    public init (httpResponse: HttpResponse, decoder: ResponseDecoder? = nil) throws {
//
//                        if case .data(let data) = httpResponse.body,
//                            let unwrappedData = data,
//                            let responseDecoder = decoder {
//                            let output: GreetingWithErrorsOutputBody = try responseDecoder.decode(responseBody: unwrappedData)
//                            self.greeting = output.greeting
//                        } else {
//                            self.greeting = nil
//                        }
//                    }
//                }
//                """.trimIndent()
//        contents.shouldContainOnlyOnce(expectedContents)
//    }
//
//    @Test
//    fun `it builds response binding for GreetingWithErrors error`() {
//        val contents = getModelFileContents("example", "GreetingWithErrorsError+ResponseInit.swift", newTestContext.manifest)
//        contents.shouldSyntacticSanityCheck()
//        val expectedContents =
//                """
//                extension GreetingWithErrorsError {
//                    public init(errorType: String?, httpResponse: HttpResponse, decoder: ResponseDecoder? = nil, message: String? = nil, requestID: String? = nil) throws {
//                        switch errorType {
//                        case "ComplexError" : self = .complexError(try ComplexError(httpResponse: httpResponse, decoder: decoder, message: message, requestID: requestID))
//                        case "FooError" : self = .fooError(try FooError(httpResponse: httpResponse, decoder: decoder, message: message, requestID: requestID))
//                        case "InvalidGreeting" : self = .invalidGreeting(try InvalidGreeting(httpResponse: httpResponse, decoder: decoder, message: message, requestID: requestID))
//                        default : self = .unknown(UnknownHttpServiceError(httpResponse: httpResponse, message: message))
//                        }
//                    }
//                }
//                """.trimIndent()
//        contents.shouldContainOnlyOnce(expectedContents)
//    }
}
