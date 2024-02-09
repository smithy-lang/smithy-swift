/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.comparables.shouldBeEqualComparingTo
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ClientProperty
import software.amazon.smithy.swift.codegen.integration.DefaultRequestEncoder
import software.amazon.smithy.swift.codegen.integration.DefaultResponseDecoder
import software.amazon.smithy.swift.codegen.integration.DefaultServiceConfig
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.HttpProtocolClientGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolClientGeneratorFactory
import software.amazon.smithy.swift.codegen.integration.HttpProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.ServiceConfig
import software.amazon.smithy.swift.codegen.middleware.OperationMiddleware
import software.amazon.smithy.swift.codegen.model.AddOperationShapes

class TestHttpProtocolClientGeneratorFactory : HttpProtocolClientGeneratorFactory {
    override fun createHttpProtocolClientGenerator(
        ctx: ProtocolGenerator.GenerationContext,
        httpBindingResolver: HttpBindingResolver,
        writer: SwiftWriter,
        serviceName: String,
        defaultContentType: String,
        httpProtocolCustomizable: HttpProtocolCustomizable,
        operationMiddleware: OperationMiddleware,
    ): HttpProtocolClientGenerator {
        val serviceSymbol = ctx.symbolProvider.toSymbol(ctx.service)
        val config = getConfigClass(writer, ctx.settings.sdkId, serviceSymbol.name)
        return HttpProtocolClientGenerator(ctx, writer, config, httpBindingResolver, defaultContentType, httpProtocolCustomizable, operationMiddleware)
    }

    private fun getClientProperties(ctx: ProtocolGenerator.GenerationContext): List<ClientProperty> {
        return mutableListOf(
            DefaultRequestEncoder(),
            DefaultResponseDecoder(),
        )
    }

    private fun getConfigClass(writer: SwiftWriter, clientName: String, serviceName: String): ServiceConfig {
        return DefaultServiceConfig(writer, clientName, serviceName)
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
        newTestContext.generator.generateCodableConformanceForNestedTypes(newTestContext.generationCtx)
        newTestContext.generationCtx.delegator.flushWriters()
    }

    @Test
    fun `it creates correct init for explicit struct payloads`() {
        val contents = getModelFileContents("example", "ExplicitStructOutput+HttpResponseBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
extension ExplicitStructOutput: ClientRuntime.HttpResponseBinding {
    public init(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder? = nil) async throws {
        if let data = try await httpResponse.body.readData(), let responseDecoder = decoder {
            let output: Nested2 = try responseDecoder.decode(responseBody: data)
            self.payload1 = output
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
        val contents = getModelFileContents("example", "HttpResponseCodeOutput+HttpResponseBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
extension HttpResponseCodeOutput: ClientRuntime.HttpResponseBinding {
    public init(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder? = nil) async throws {
        self.status = await httpResponse.statusCode.rawValue
    }
}
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `decode the document type in HttpResponseBinding`() {
        val contents = getModelFileContents("example", "InlineDocumentAsPayloadOutput+HttpResponseBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
extension InlineDocumentAsPayloadOutput: ClientRuntime.HttpResponseBinding {
    public init(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder? = nil) async throws {
        if let data = try await httpResponse.body.readData(), let responseDecoder = decoder {
            let output: ClientRuntime.Document = try responseDecoder.decode(responseBody: data)
            self.documentValue = output
        } else {
            self.documentValue = nil
        }
    }
}
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `default fooMap to an empty map if keysForFooMap is empty`() {
        val contents = getModelFileContents("example", "HttpPrefixHeadersOutput+HttpResponseBinding.swift", newTestContext.manifest)
        val expectedContents =
            """
            extension HttpPrefixHeadersOutput: ClientRuntime.HttpResponseBinding {
                public init(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder? = nil) async throws {
                    if let fooHeaderValue = await httpResponse.headers.value(for: "X-Foo") {
                        self.foo = fooHeaderValue
                    } else {
                        self.foo = nil
                    }
                    let keysForFooMap = await httpResponse.headers.dictionary.keys.filter({ ${'$'}0.starts(with: "X-Foo-") })
                    if (!keysForFooMap.isEmpty) {
                        var mapMember = [Swift.String: String]()
                        for headerKey in keysForFooMap {
                            let mapMemberValue = await httpResponse.headers.dictionary[headerKey]?[0]
                            let mapMemberKey = headerKey.removePrefix("X-Foo-")
                            mapMember[mapMemberKey] = mapMemberValue
                        }
                        self.fooMap = mapMember
                    } else {
                        self.fooMap = [:]
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
