/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.comparables.shouldBeEqualComparingTo
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ClientProperty
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
        return listOf()
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
        val expectedContents = """
extension ExplicitStructOutput {

    static var httpBinding: SmithyReadWrite.WireResponseOutputBinding<ClientRuntime.HttpResponse, ExplicitStructOutput, SmithyJSON.Reader> {
        { httpResponse, responseDocumentClosure in
            let responseReader = try await responseDocumentClosure(httpResponse)
            let reader = responseReader
            var value = ExplicitStructOutput()
            value.payload1 = try reader.readIfPresent(with: Nested2.read(from:))
            return value
        }
    }
}
"""
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
        val expectedContents = """
extension HttpResponseCodeOutput {

    static var httpBinding: SmithyReadWrite.WireResponseOutputBinding<ClientRuntime.HttpResponse, HttpResponseCodeOutput, SmithyJSON.Reader> {
        { httpResponse, responseDocumentClosure in
            var value = HttpResponseCodeOutput()
            value.status = httpResponse.statusCode.rawValue
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `decode the document type in HttpResponseBinding`() {
        val contents = getModelFileContents("example", "InlineDocumentAsPayloadOutput+HttpResponseBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension InlineDocumentAsPayloadOutput {

    static var httpBinding: SmithyReadWrite.WireResponseOutputBinding<ClientRuntime.HttpResponse, InlineDocumentAsPayloadOutput, SmithyJSON.Reader> {
        { httpResponse, responseDocumentClosure in
            let responseReader = try await responseDocumentClosure(httpResponse)
            let reader = responseReader
            var value = InlineDocumentAsPayloadOutput()
            if let data = try await httpResponse.body.readData() {
                value.documentValue = try SmithyReadWrite.Document.document(from: data)
            }
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `default fooMap to an empty map if keysForFooMap is empty`() {
        val contents = getModelFileContents("example", "HttpPrefixHeadersOutput+HttpResponseBinding.swift", newTestContext.manifest)
        val expectedContents = """
extension HttpPrefixHeadersOutput {

    static var httpBinding: SmithyReadWrite.WireResponseOutputBinding<ClientRuntime.HttpResponse, HttpPrefixHeadersOutput, SmithyJSON.Reader> {
        { httpResponse, responseDocumentClosure in
            var value = HttpPrefixHeadersOutput()
            if let fooHeaderValue = httpResponse.headers.value(for: "X-Foo") {
                value.foo = fooHeaderValue
            }
            let keysForFooMap = httpResponse.headers.dictionary.keys.filter({ ${'$'}0.starts(with: "X-Foo-") })
            if (!keysForFooMap.isEmpty) {
                var mapMember = [Swift.String: String]()
                for headerKey in keysForFooMap {
                    let mapMemberValue = httpResponse.headers.dictionary[headerKey]?[0]
                    let mapMemberKey = headerKey.removePrefix("X-Foo-")
                    mapMember[mapMemberKey] = mapMemberValue
                }
                value.fooMap = mapMember
            } else {
                value.fooMap = [:]
            }
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
