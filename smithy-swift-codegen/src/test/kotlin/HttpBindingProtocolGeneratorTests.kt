/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.comparables.shouldBeEqualComparingTo
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.AddOperationShapes
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
class HttpBindingProtocolGeneratorTests {
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
        val contents = getModelFileContents("example", "SmokeTestInput+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
                extension SmokeTestInput: HttpRequestBinding, Reflection {
                    public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {
                        let builder = SdkHttpRequestBuilder()
                        if let query1 = query1 {
                            let queryItem = URLQueryItem(name: "Query1", value: String(query1))
                            builder.withQueryItem(queryItem)
                        }
                        builder.withHeader(name: "Content-Type", value: "application/json")
                        if let header1 = header1 {
                            builder.withHeader(name: "X-Header1", value: String(header1))
                        }
                        if let header2 = header2 {
                            builder.withHeader(name: "X-Header2", value: String(header2))
                        }
                        if try !self.allPropertiesAreNull() {
                            let data = try encoder.encode(self)
                            let body = HttpBody.data(data)
                            builder.withHeader(name: "Content-Length", value: String(data.count))
                            builder.withBody(body)
                        }
                        return builder
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
                public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {
                    let builder = SdkHttpRequestBuilder()
                    builder.withHeader(name: "Content-Type", value: "text/plain")
                    if let payload1 = self.payload1 {
                        let data = payload1.data(using: .utf8)
                        let body = HttpBody.data(data)
                        builder.withHeader(name: "Content-Length", value: String(data.count))
                        builder.withBody(body)
                    }
                    return builder
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
                public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {
                    let builder = SdkHttpRequestBuilder()
                    builder.withHeader(name: "Content-Type", value: "application/octet-stream")
                    if let payload1 = self.payload1 {
                        let data = payload1
                        let body = HttpBody.data(data)
                        builder.withHeader(name: "Content-Length", value: String(data.count))
                        builder.withBody(body)
                    }
                    return builder
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
                public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {
                    let builder = SdkHttpRequestBuilder()
                    builder.withHeader(name: "Content-Type", value: "application/octet-stream")
                    if let payload1 = self.payload1 {
                        let data = payload1
                        let body = HttpBody.data(data)
                        builder.withHeader(name: "Content-Length", value: String(data.count))
                        builder.withBody(body)
                    }
                    return builder
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
                public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {
                    let builder = SdkHttpRequestBuilder()
                    builder.withHeader(name: "Content-Type", value: "application/json")
                    if let payload1 = self.payload1 {
                        let data = try encoder.encode(payload1)
                        let body = HttpBody.data(data)
                        builder.withHeader(name: "Content-Length", value: String(data.count))
                        builder.withBody(body)
                    }
                    return builder
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
                public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {
                    let builder = SdkHttpRequestBuilder()
                    builder.withHeader(name: "Content-Type", value: "application/json")
                    if try !self.allPropertiesAreNull() {
                        let data = try encoder.encode(self)
                        let body = HttpBody.data(data)
                        builder.withHeader(name: "Content-Length", value: String(data.count))
                        builder.withBody(body)
                    }
                    return builder
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
                public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {
                    let builder = SdkHttpRequestBuilder()
                    builder.withHeader(name: "Content-Type", value: "application/json")
                    if let enumHeader = enumHeader {
                        builder.withHeader(name: "X-EnumHeader", value: String(enumHeader.rawValue))
                    }
                    if try !self.allPropertiesAreNull() {
                        let data = try encoder.encode(self)
                        let body = HttpBody.data(data)
                        builder.withHeader(name: "Content-Length", value: String(data.count))
                        builder.withBody(body)
                    }
                    return builder
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
                public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {
                    let builder = SdkHttpRequestBuilder()
                    if let queryTimestamp = queryTimestamp {
                        let queryItem = URLQueryItem(name: "qtime", value: String(queryTimestamp.iso8601WithoutFractionalSeconds()))
                        builder.withQueryItem(queryItem)
                    }
                    if let queryTimestampList = queryTimestampList {
                        queryTimestampList.forEach { queryItemValue in
                            let queryItem = URLQueryItem(name: "qtimeList", value: String(queryItemValue.iso8601WithoutFractionalSeconds()))
                            builder.withQueryItem(queryItem)
                        }
                    }
                    builder.withHeader(name: "Content-Type", value: "application/json")
                    if let headerEpoch = headerEpoch {
                        builder.withHeader(name: "X-Epoch", value: String(headerEpoch.timeIntervalSince1970.clean))
                    }
                    if let headerHttpDate = headerHttpDate {
                        builder.withHeader(name: "X-Date", value: String(headerHttpDate.rfc5322()))
                    }
                    if try !self.allPropertiesAreNull() {
                        let data = try encoder.encode(self)
                        let body = HttpBody.data(data)
                        builder.withHeader(name: "Content-Length", value: String(data.count))
                        builder.withBody(body)
                    }
                    return builder
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
    fun `decode the document type in HttpResponseBinding`() {
        val contents = getModelFileContents("example", "InlineDocumentAsPayloadOutput+ResponseInit.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
extension InlineDocumentAsPayloadOutput: HttpResponseBinding {
    public init (httpResponse: HttpResponse, decoder: ResponseDecoder? = nil) throws {

        if case .data(let data) = httpResponse.body,
           let unwrappedData = data {
            if let responseDecoder = decoder {
                let output: Document = try responseDecoder.decode(responseBody: unwrappedData)
                self.documentValue = output
            } else {
                self.documentValue = nil
            }
        } else {
            self.documentValue = nil
        }
    }
}
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request with idempotency token trait for httpQuery`() {
        val contents =
            getModelFileContents("example", "QueryIdempotencyTokenAutoFillInput+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
                extension QueryIdempotencyTokenAutoFillInput: HttpRequestBinding, Reflection {
                    public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {
                        let builder = SdkHttpRequestBuilder()
                        if let token = token {
                            let queryItem = URLQueryItem(name: "token", value: String(token))
                            builder.withQueryItem(queryItem)
                        }
                        else {
                            let queryItem = URLQueryItem(name: "token", value: idempotencyTokenGenerator.generateToken())
                            builder.withQueryItem(queryItem)
                        }
                        return builder
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request with idempotency token trait for httpHeader`() {
        val contents = getModelFileContents(
            "example",
            "IdempotencyTokenWithHttpHeaderInput+HttpRequestBinding.swift",
            newTestContext.manifest
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
                extension IdempotencyTokenWithHttpHeaderInput: HttpRequestBinding, Reflection {
                    public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {
                        let builder = SdkHttpRequestBuilder()
                        if let header = header {
                            builder.withHeader(name: "token", value: String(header))
                        }
                        else {
                            builder.withHeader(name: "token", value: idempotencyTokenGenerator.generateToken())
                        }
                        return builder
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    // The following 3 HttpRequestBinding generation tests correspond to idempotency token targeting a member in the body/payload of request
    @Test
    fun `it builds request with idempotency token trait and httpPayload trait on same member`() {
        /*
        * Case 1 : Idempotency token trait and httpPayload trait on same string member "bodyAndToken"
            structure IdempotencyTokenWithHttpPayloadTraitOnTokenInput {
                @httpPayload
                @idempotencyToken
                bodyIsToken: String,
            }
        * */
        val contents = getModelFileContents(
            "example",
            "IdempotencyTokenWithHttpPayloadTraitOnTokenInput+HttpRequestBinding.swift",
            newTestContext.manifest
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
                extension IdempotencyTokenWithHttpPayloadTraitOnTokenInput: HttpRequestBinding, Reflection {
                    public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {
                        let builder = SdkHttpRequestBuilder()
                        builder.withHeader(name: "Content-Type", value: "text/plain")
                        if let bodyIsToken = self.bodyIsToken {
                            let data = bodyIsToken.data(using: .utf8)
                            let body = HttpBody.data(data)
                            builder.withHeader(name: "Content-Length", value: String(data.count))
                            builder.withBody(body)
                        }
                        let data = idempotencyTokenGenerator.generateToken().data(using: .utf8)
                        let body = HttpBody.data(data)
                        builder.withHeader(name: "Content-Length", value: String(data.count))
                        builder.withBody(body)
                        return builder
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request with idempotency token trait and without httpPayload trait on any member`() {
        /*
        Case 2: Idempotency token in the http body and without httpPayload trait on any member
        structure IdempotencyTokenWithoutHttpPayloadTraitOnAnyMemberInput {
            stringValue: String,
            documentValue: Document,

            @idempotencyToken
            token: String,
        }
        - No change to existing code in HttpRequestBinding file. We changed in "encodable" file for the
          struct containing these members.
        * */
        val contents = getModelFileContents(
            "example",
            "IdempotencyTokenWithoutHttpPayloadTraitOnAnyMemberInput+HttpRequestBinding.swift",
            newTestContext.manifest
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
                extension IdempotencyTokenWithoutHttpPayloadTraitOnAnyMemberInput: HttpRequestBinding, Reflection {
                    public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {
                        let builder = SdkHttpRequestBuilder()
                        builder.withHeader(name: "Content-Type", value: "application/json")
                        if try !self.allPropertiesAreNull() {
                            let data = try encoder.encode(self)
                            let body = HttpBody.data(data)
                            builder.withHeader(name: "Content-Length", value: String(data.count))
                            builder.withBody(body)
                        }
                        return builder
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request with idempotency token and httpPayload traits on different members`() {
        /*
        Case 3: Idempotency token trait and httpPayload trait on different members
        structure IdempotencyTokenWithoutHttpPayloadTraitOnTokenInput {
            @httpPayload
            body: String,

            @httpHeader("token")
            @idempotencyToken
            token: String,
        }
        - Idempotency token is bound to httpHeader in this case.
        * */
        val contents = getModelFileContents(
            "example",
            "IdempotencyTokenWithoutHttpPayloadTraitOnTokenInput+HttpRequestBinding.swift",
            newTestContext.manifest
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
                extension IdempotencyTokenWithoutHttpPayloadTraitOnTokenInput: HttpRequestBinding, Reflection {
                    public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {
                        let builder = SdkHttpRequestBuilder()
                        builder.withHeader(name: "Content-Type", value: "text/plain")
                        if let token = token {
                            builder.withHeader(name: "token", value: String(token))
                        }
                        else {
                            builder.withHeader(name: "token", value: idempotencyTokenGenerator.generateToken())
                        }
                        if let body = self.body {
                            let data = body.data(using: .utf8)
                            let body = HttpBody.data(data)
                            builder.withHeader(name: "Content-Length", value: String(data.count))
                            builder.withBody(body)
                        }
                        return builder
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
