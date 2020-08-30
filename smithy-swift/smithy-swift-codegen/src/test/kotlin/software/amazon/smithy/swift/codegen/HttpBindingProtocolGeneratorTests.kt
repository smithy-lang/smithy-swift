/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
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
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class MockHttpProtocolGenerator : HttpBindingProtocolGenerator() {
    override val defaultContentType: String = "application/json"
    override val defaultTimestampFormat: TimestampFormatTrait.Format = TimestampFormatTrait.Format.DATE_TIME
    override val protocol: ShapeId = RestJson1Trait.ID

    override fun generateProtocolUnitTests(ctx: ProtocolGenerator.GenerationContext) {}
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
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName);
        val delegator = SwiftDelegator(settings, model, manifest, provider)
        val generator = MockHttpProtocolGenerator()
        val ctx = ProtocolGenerator.GenerationContext(settings, model, service, provider, listOf(), generator.protocol, delegator)
        return TestContext(ctx, manifest, generator)
    }

    val newTestContext = newTestContext()

    init {
        newTestContext.generator.generateSerializers(newTestContext.ctx)
        newTestContext.generator.generateProtocolClient(newTestContext.ctx)
        newTestContext.ctx.delegator.flushWriters()
    }

    @Test
    fun `it creates smoke test request serializer`() {
        val contents = getModelFileContents("example", "SmokeTestRequest+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
                    extension SmokeTestRequest: HttpRequestBinding {
                        public func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
                            var queryItems: [URLQueryItem] = [URLQueryItem]()
                            if let query1 = query1 {
                                let queryItem = URLQueryItem(name: "Query1", value: String(query1))
                                queryItems.append(queryItem)
                            }
                            let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                            var headers = HttpHeaders()
                            headers.add(name: "Content-Type", value: "application/json")
                            if let header1 = header1 {
                                headers.add(name: "X-Header1", value: String(header1))
                            }
                            if let header2 = header2 {
                                headers.add(name: "X-Header2", value: String(header2))
                            }
                            return HttpRequest(method: method, endpoint: endpoint, headers: headers)
                        }
                    }
                """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it serializes explicit string payloads`() {
        val contents = getModelFileContents("example", "ExplicitStringRequest+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
                extension ExplicitStringRequest: HttpRequestBinding {
                    public func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
                        var queryItems: [URLQueryItem] = [URLQueryItem]()
                        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                        var headers = HttpHeaders()
                        headers.add(name: "Content-Type", value: "text/plain")
                        return HttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it serializes explicit blob payloads`() {
        val contents = getModelFileContents("example", "ExplicitBlobRequest+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
                extension ExplicitBlobRequest: HttpRequestBinding {
                    public func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
                        var queryItems: [URLQueryItem] = [URLQueryItem]()
                        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                        var headers = HttpHeaders()
                        headers.add(name: "Content-Type", value: "application/octet-stream")
                        return HttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it serializes explicit streaming blob payloads`() {
        val contents = getModelFileContents("example", "ExplicitBlobStreamRequest+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
                extension ExplicitBlobStreamRequest: HttpRequestBinding {
                    public func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
                        var queryItems: [URLQueryItem] = [URLQueryItem]()
                        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                        var headers = HttpHeaders()
                        headers.add(name: "Content-Type", value: "application/octet-stream")
                        return HttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it serializes explicit struct payloads`() {
        val contents = getModelFileContents("example", "ExplicitStructRequest+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
                extension ExplicitStructRequest: HttpRequestBinding {
                    public func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
                        var queryItems: [URLQueryItem] = [URLQueryItem]()
                        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                        var headers = HttpHeaders()
                        headers.add(name: "Content-Type", value: "application/json")
                        return HttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it serializes operation inputs with lists`() {
        val contents = getModelFileContents("example", "ListInputRequest+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
                extension ListInputRequest: HttpRequestBinding {
                    public func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
                        var queryItems: [URLQueryItem] = [URLQueryItem]()
                        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                        var headers = HttpHeaders()
                        headers.add(name: "Content-Type", value: "application/json")
                        return HttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it serializes enums as raw values`() {
        val contents = getModelFileContents("example", "EnumInputRequest+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
                extension EnumInputRequest: HttpRequestBinding {
                    public func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
                        var queryItems: [URLQueryItem] = [URLQueryItem]()
                        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                        var headers = HttpHeaders()
                        headers.add(name: "Content-Type", value: "application/json")
                        if let enumHeader = enumHeader {
                            headers.add(name: "X-EnumHeader", value: String(enumHeader.rawValue))
                        }
                        return HttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

//    @Test
//    fun `it serializes timestamps with format`() {
//        val contents = getModelFileContents("Example", "TimestampInputRequest.swift", newTestContext.manifest)
//        contents.shouldSyntacticSanityCheck()
//        val expectedContents =
//            """
//            extension TimestampInputRequest: HttpRequestBinding {
//                public func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
//                    var queryItems: [URLQueryItem] = [URLQueryItem]()
//                    var queryItem: URLQueryItem
//                    if let queryTimestamp = queryTimestamp {
//                        queryItem = URLQueryItem(name: "qtime", value: String(DateFormatter.iso8601DateFormatterWithoutFractionalSeconds.string(from: queryTimestamp)))
//                        queryItems.append(queryItem)
//                    }
//                    if let queryTimestampList = queryTimestampList {
//                        queryTimestampList.forEach { queryItemValue in
//                            queryItem = URLQueryItem(name: "qtimeList", value: String(DateFormatter.iso8601DateFormatterWithoutFractionalSeconds.string(from: queryItemValue)))
//                            queryItems.append(queryItem)
//                        }
//                    }
//                    let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
//                    var headers = HttpHeaders()
//                    headers.add(name: "Content-Type", value: "application/json")
//                    if let headerEpoch = headerEpoch {
//                        headers.add(name: "X-Epoch", value: String(DateFormatter.rfc5322DateFormatter.string(from: headerEpoch)))
//                    }
//                    if let headerHttpDate = headerHttpDate {
//                        headers.add(name: "X-Date", value: String(DateFormatter.rfc5322DateFormatter.string(from: headerHttpDate)))
//                    }
//                    return HttpRequest(method: method, endpoint: endpoint, headers: headers)
//                }
//            }
//            """.trimIndent()
//        contents.shouldContainOnlyOnce(expectedContents)
//    }

    @Test
    fun `getSanitizedName generates Swifty name`() {
        val testProtocolName = "aws.rest-json-1.1"
        val sanitizedProtocolName = ProtocolGenerator.getSanitizedName(testProtocolName)
        sanitizedProtocolName.shouldBeEqualComparingTo("AWSRestJson1_1")
    }
}
