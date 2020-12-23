/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen

import io.kotest.matchers.comparables.shouldBeEqualComparingTo
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
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

class MockHttpProtocolGenerator : HttpBindingProtocolGenerator() {
    override val defaultContentType: String = "application/json"
    override val defaultTimestampFormat: TimestampFormatTrait.Format = TimestampFormatTrait.Format.DATE_TIME
    override val protocol: ShapeId = RestJson1Trait.ID

    override fun generateProtocolUnitTests(ctx: ProtocolGenerator.GenerationContext) {
        val ignoredTests = setOf(
            // FIXME - document type not fully supported yet
            "InlineDocumentInput",
            "InlineDocumentAsPayloadInput",
            "InlineDocumentOutput",
            "InlineDocumentAsPayloadInputOutput"
        )

        val requestTestBuilder = HttpProtocolUnitTestRequestGenerator.Builder()
        val responseTestBuilder = HttpProtocolUnitTestResponseGenerator.Builder()
        val errorTestBuilder = HttpProtocolUnitTestErrorGenerator.Builder()

        HttpProtocolTestGenerator(
            ctx,
            requestTestBuilder,
            responseTestBuilder,
            errorTestBuilder,
            ignoredTests
        ).generateProtocolTests()
    }
}

// NOTE: protocol conformance is mostly handled by the protocol tests suite
class HttpBindingProtocolGeneratorTests : TestsBase() {
    var model = createModelFromSmithy("http-binding-protocol-generator-test.smithy")

    data class TestContext(val ctx: ProtocolGenerator.GenerationContext, val manifest: MockManifest, val generator: MockHttpProtocolGenerator)

    private fun newTestContext(): TestContext {
        val manifest = MockManifest()
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "Example")
        val serviceShapeIdWithNamespace = "com.test#Example"
        val service = model.getShape(ShapeId.from(serviceShapeIdWithNamespace)).get().asServiceShape().get()
        val settings = SwiftSettings.from(model, buildDefaultSwiftSettingsObjectNode(serviceShapeIdWithNamespace))
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        val delegator = SwiftDelegator(settings, model, manifest, provider)
        val generator = MockHttpProtocolGenerator()
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

    @Test
    fun `it creates smoke test request builder`() {
        val contents = getModelFileContents("example", "SmokeTestInput+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
                extension SmokeTestInput: HttpRequestBinding, Reflection {
                    public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequest {
                        var queryItems: [URLQueryItem] = [URLQueryItem]()
                        if let query1 = query1 {
                            let queryItem = URLQueryItem(name: "Query1", value: String(query1))
                            queryItems.append(queryItem)
                        }
                        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                        var headers = Headers()
                        headers.add(name: "Content-Type", value: "application/json")
                        if let header1 = header1 {
                            headers.add(name: "X-Header1", value: String(header1))
                        }
                        if let header2 = header2 {
                            headers.add(name: "X-Header2", value: String(header2))
                        }
                        if try !self.allPropertiesAreNull() {
                            let data = try encoder.encode(self)
                            let body = HttpBody.data(data)
                            headers.add(name: "Content-Length", value: String(data.count))
                            return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers, body: body)
                        } else {
                            return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers)
                        }
                    }
                }
                """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request for explicit string payloads`() {
        val contents = getModelFileContents("example", "ExplicitStringInput+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension ExplicitStringInput: HttpRequestBinding, Reflection {
                public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequest {
                    var queryItems: [URLQueryItem] = [URLQueryItem]()
                    let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                    var headers = Headers()
                    headers.add(name: "Content-Type", value: "text/plain")
                    if let payload1 = self.payload1 {
                        let data = payload1.data(using: .utf8)
                        let body = HttpBody.data(data)
                        headers.add(name: "Content-Length", value: String(data.count))
                        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers, body: body)
                    } else {
                        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request for explicit blob payloads`() {
        val contents = getModelFileContents("example", "ExplicitBlobInput+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension ExplicitBlobInput: HttpRequestBinding, Reflection {
                public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequest {
                    var queryItems: [URLQueryItem] = [URLQueryItem]()
                    let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                    var headers = Headers()
                    headers.add(name: "Content-Type", value: "application/octet-stream")
                    if let payload1 = self.payload1 {
                        let data = payload1
                        let body = HttpBody.data(data)
                        headers.add(name: "Content-Length", value: String(data.count))
                        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers, body: body)
                    } else {
                        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request for explicit streaming blob payloads`() {
        val contents = getModelFileContents("example", "ExplicitBlobStreamInput+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension ExplicitBlobStreamInput: HttpRequestBinding, Reflection {
                public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequest {
                    var queryItems: [URLQueryItem] = [URLQueryItem]()
                    let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                    var headers = Headers()
                    headers.add(name: "Content-Type", value: "application/octet-stream")
                    if let payload1 = self.payload1 {
                        let data = payload1
                        let body = HttpBody.data(data)
                        headers.add(name: "Content-Length", value: String(data.count))
                        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers, body: body)
                    } else {
                        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request for explicit struct payloads`() {
        val contents = getModelFileContents("example", "ExplicitStructInput+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension ExplicitStructInput: HttpRequestBinding, Reflection {
                public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequest {
                    var queryItems: [URLQueryItem] = [URLQueryItem]()
                    let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                    var headers = Headers()
                    headers.add(name: "Content-Type", value: "application/json")
                    if let payload1 = self.payload1 {
                        let data = try encoder.encode(payload1)
                        let body = HttpBody.data(data)
                        headers.add(name: "Content-Length", value: String(data.count))
                        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers, body: body)
                    } else {
                        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request for operation inputs with lists`() {
        val contents = getModelFileContents("example", "ListInputInput+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension ListInputInput: HttpRequestBinding, Reflection {
                public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequest {
                    var queryItems: [URLQueryItem] = [URLQueryItem]()
                    let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                    var headers = Headers()
                    headers.add(name: "Content-Type", value: "application/json")
                    if try !self.allPropertiesAreNull() {
                        let data = try encoder.encode(self)
                        let body = HttpBody.data(data)
                        headers.add(name: "Content-Length", value: String(data.count))
                        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers, body: body)
                    } else {
                        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request with enums as raw values in the header`() {
        val contents = getModelFileContents("example", "EnumInputInput+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension EnumInputInput: HttpRequestBinding, Reflection {
                public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequest {
                    var queryItems: [URLQueryItem] = [URLQueryItem]()
                    let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                    var headers = Headers()
                    headers.add(name: "Content-Type", value: "application/json")
                    if let enumHeader = enumHeader {
                        headers.add(name: "X-EnumHeader", value: String(enumHeader.rawValue))
                    }
                    if try !self.allPropertiesAreNull() {
                        let data = try encoder.encode(self)
                        let body = HttpBody.data(data)
                        headers.add(name: "Content-Length", value: String(data.count))
                        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers, body: body)
                    } else {
                        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates http builder for timestamps with format`() {
        val contents = getModelFileContents("example", "TimestampInputInput+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension TimestampInputInput: HttpRequestBinding, Reflection {
                public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequest {
                    var queryItems: [URLQueryItem] = [URLQueryItem]()
                    if let queryTimestamp = queryTimestamp {
                        let queryItem = URLQueryItem(name: "qtime", value: String(queryTimestamp.iso8601WithoutFractionalSeconds()))
                        queryItems.append(queryItem)
                    }
                    if let queryTimestampList = queryTimestampList {
                        queryTimestampList.forEach { queryItemValue in
                            let queryItem = URLQueryItem(name: "qtimeList", value: String(queryItemValue.iso8601WithoutFractionalSeconds()))
                            queryItems.append(queryItem)
                        }
                    }
                    let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                    var headers = Headers()
                    headers.add(name: "Content-Type", value: "application/json")
                    if let headerEpoch = headerEpoch {
                        headers.add(name: "X-Epoch", value: String(headerEpoch.timeIntervalSince1970.clean))
                    }
                    if let headerHttpDate = headerHttpDate {
                        headers.add(name: "X-Date", value: String(headerHttpDate.rfc5322()))
                    }
                    if try !self.allPropertiesAreNull() {
                        let data = try encoder.encode(self)
                        let body = HttpBody.data(data)
                        headers.add(name: "Content-Length", value: String(data.count))
                        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers, body: body)
                    } else {
                        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            }
""".trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates correct init for explicit struct payloads`() {
        val contents = getModelFileContents("example", "ExplicitStructOutput+ResponseInit.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
extension ExplicitStructOutput: HttpResponseBinding {
    public init (httpResponse: HttpResponse, decoder: ResponseDecoder? = nil) throws {

        if case .data(let data) = httpResponse.body,
           let unwrappedData = data {
            if let responseDecoder = decoder {
                let output: Nested2 = try responseDecoder.decode(responseBody: unwrappedData)
                self.payload1 = output
            } else {
                self.payload1 = nil
            }
        } else {
            self.payload1 = nil
        }
    }
}
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `getSanitizedName generates Swifty name`() {
        val testProtocolName = "aws.rest-json-1.1"
        val sanitizedProtocolName = ProtocolGenerator.getSanitizedName(testProtocolName)
        sanitizedProtocolName.shouldBeEqualComparingTo("AWSRestJson1_1")
    }

    @Test
    fun `httpResponseCodeOutput response init content`() {
        val contents = getModelFileContents("example", "HttpResponseCodeOutput+ResponseInit.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
extension HttpResponseCodeOutput: HttpResponseBinding {
    public init (httpResponse: HttpResponse, decoder: ResponseDecoder? = nil) throws {

        self.status = httpResponse.statusCode.rawValue
    }
}
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request with idempotency token trait for httpQuery`() {
        val contents = getModelFileContents("example", "QueryIdempotencyTokenAutoFillInput+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
extension QueryIdempotencyTokenAutoFillInput: HttpRequestBinding, Reflection {
    public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequest {
        var queryItems: [URLQueryItem] = [URLQueryItem]()
        if let token = token {
            let queryItem = URLQueryItem(name: "token", value: String(token))
            queryItems.append(queryItem)
        }
        else {
            let queryItem = URLQueryItem(name: "token", value: idempotencyTokenGenerator.generateToken())
            queryItems.append(queryItem)
        }
        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
        var headers = Headers()
        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers)
    }
}
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request with idempotency token trait for httpHeader`() {
        val contents = getModelFileContents("example", "IdempotencyTokenWithHttpHeaderInput+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
extension IdempotencyTokenWithHttpHeaderInput: HttpRequestBinding, Reflection {
    public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequest {
        var queryItems: [URLQueryItem] = [URLQueryItem]()
        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
        var headers = Headers()
        if let header = header {
            headers.add(name: "token", value: String(header))
        }
        else {
            headers.add(name: "token", value: idempotencyTokenGenerator.generateToken())
        }
        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers)
    }
}
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request with idempotency token trait and httpPayload trait on same member`() {
        val contents = getModelFileContents("example", "IdempotencyTokenWithHttpPayloadTraitOnTokenInput+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
extension IdempotencyTokenWithHttpPayloadTraitOnTokenInput: HttpRequestBinding, Reflection {
    public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequest {
        var queryItems: [URLQueryItem] = [URLQueryItem]()
        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
        var headers = Headers()
        headers.add(name: "Content-Type", value: "text/plain")
        if let bodyAndToken = self.bodyAndToken {
            let data = bodyAndToken.data(using: .utf8)
            let body = HttpBody.data(data)
            headers.add(name: "Content-Length", value: String(data.count))
            return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers, body: body)
        } else {
            let data = idempotencyTokenGenerator.generateToken().data(using: .utf8)
            let body = HttpBody.data(data)
            headers.add(name: "Content-Length", value: String(data.count))
            return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers, body: body)
        }
    }
}
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request with idempotency token trait and without httpPayload trait on any member`() {
        val contents = getModelFileContents("example", "IdempotencyTokenWithoutHttpPayloadTraitOnAnyMemberInput+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
extension IdempotencyTokenWithoutHttpPayloadTraitOnAnyMemberInput: HttpRequestBinding, Reflection {
    public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequest {
        var queryItems: [URLQueryItem] = [URLQueryItem]()
        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
        var headers = Headers()
        headers.add(name: "Content-Type", value: "application/json")
        if try !self.allPropertiesAreNull() {
            let data = try encoder.encode(self)
            let body = HttpBody.data(data)
            headers.add(name: "Content-Length", value: String(data.count))
            return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers, body: body)
        } else {
            let data = idempotencyTokenGenerator.generateToken().data(using: .utf8)
            let body = HttpBody.data(data)
            headers.add(name: "Content-Length", value: String(data.count))
            return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers, body: body)
        }
    }
}
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
