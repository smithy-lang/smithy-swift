/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.comparables.shouldBeEqualComparingTo
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.AddOperationShapes
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ClientProperty
import software.amazon.smithy.swift.codegen.integration.DefaultConfig
import software.amazon.smithy.swift.codegen.integration.DefaultRequestEncoder
import software.amazon.smithy.swift.codegen.integration.DefaultResponseDecoder
import software.amazon.smithy.swift.codegen.integration.ErrorFromHttpResponseGenerator
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.HttpProtocolClientGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolClientGeneratorFactory
import software.amazon.smithy.swift.codegen.integration.HttpProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.ServiceConfig

class TestErrorFromHttpResponseGenerator : ErrorFromHttpResponseGenerator {
    override fun generateInitOperationFromHttpResponse(ctx: ProtocolGenerator.GenerationContext, op: OperationShape) {
        val operationErrorName = ServiceGenerator.getOperationErrorShapeName(op)
        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$operationErrorName+ResponseInit.swift")
            .name(operationErrorName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            writer.openBlock("extension \$L {", "}", operationErrorName) {
                writer.openBlock("public init(httpResponse: HttpResponse, decoder: ResponseDecoder? = nil) throws {", "}") {
                    writer.write("throw ClientError.deserializationFailed(ClientError.dataNotFound(\"Invalid information in current codegen context to resolve the ErrorType\"))")
                }
            }
        }
    }
}

class TestHttpProtocolClientGeneratorFactory : HttpProtocolClientGeneratorFactory {
    override fun createHttpProtocolClientGenerator(
        ctx: ProtocolGenerator.GenerationContext,
        httpBindingResolver: HttpBindingResolver,
        writer: SwiftWriter,
        serviceName: String,
        defaultContentType: String,
        httpProtocolCustomizable: HttpProtocolCustomizable
    ): HttpProtocolClientGenerator {
        val properties = getClientProperties(ctx)
        val serviceSymbol = ctx.symbolProvider.toSymbol(ctx.service)
        val config = getConfigClass(writer, serviceSymbol.name)
        return HttpProtocolClientGenerator(ctx, writer, properties, config, httpBindingResolver, defaultContentType, httpProtocolCustomizable)
    }

    private fun getClientProperties(ctx: ProtocolGenerator.GenerationContext): List<ClientProperty> {
        return mutableListOf(
            DefaultRequestEncoder(),
            DefaultResponseDecoder()
        )
    }

    private fun getConfigClass(writer: SwiftWriter, serviceName: String): ServiceConfig {
        return DefaultConfig(writer, serviceName)
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
}
