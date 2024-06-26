/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.IdempotencyTokenTrait
import software.amazon.smithy.protocoltests.traits.HttpRequestTestCase
import software.amazon.smithy.rulesengine.traits.EndpointRuleSetTrait
import software.amazon.smithy.swift.codegen.ShapeValueGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.hasStreamingMember
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.ResponseClosureUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.WireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.requestWireProtocol
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer
import software.amazon.smithy.swift.codegen.model.toUpperCamelCase
import software.amazon.smithy.swift.codegen.model.toLowerCamelCase
import software.amazon.smithy.swift.codegen.swiftFunctionParameterIndent
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyStreamsTypes

open class HttpProtocolUnitTestRequestGenerator protected constructor(builder: Builder) :
    HttpProtocolUnitTestGenerator<HttpRequestTestCase>(builder) {
    override val baseTestClassName = "HttpRequestTestBase"

    override fun renderTestBody(test: HttpRequestTestCase) {
        renderExpectedBlock(test)
        writer.write("")
        renderClientBlock(test)
        renderOperationBlock(test)
    }

    private fun renderExpectedBlock(test: HttpRequestTestCase) {
        var resolvedHostValue = if (test.resolvedHost.isPresent && test.resolvedHost.get() != "") test.resolvedHost.get() else "example.com"
        var hostValue = if (test.host.isPresent && test.host.get() != "") test.host.get() else "example.com"

        // Normalize the URI
        val normalizedUri = when {
            test.uri == "/" -> "/"
            test.uri.isEmpty() -> ""
            else -> {
                val trimmedUri = test.uri.removeSuffix("/")
                if (!trimmedUri.startsWith('/')) "/$trimmedUri" else trimmedUri
            }
        }

        writer.write("let urlPrefix = urlPrefixFromHost(host: \$S)", test.host)
        writer.write("let hostOnly = hostOnlyFromHost(host: \$S)", test.host)
        writer.openBlock("let expected = buildExpectedHttpRequest(")
            .write("method: .${test.method.toLowerCase()},")
            .write("path: \$S,", normalizedUri)
            .call { renderExpectedHeaders(test) }
            .call { renderExpectedQueryParams(test) }
            .call { renderExpectedBody(test) }
            .write("host: \$S,", hostValue)
            .write("resolvedHost: \$S", resolvedHostValue)
            .closeBlock(")")
    }

    private fun renderExpectedBody(test: HttpRequestTestCase) {
        if (test.body.isPresent && test.body.get().isNotBlank()) {
            operation.input.ifPresent {
                val inputShape = model.expectShape(it) as StructureShape
                val data = writer.format(
                    "Data(\"\"\"\n\$L\n\"\"\".utf8)",
                    test.body.get().replace("\\\"", "\\\\\"")
                )
                // depending on the shape of the input, wrap the expected body in a stream or not
                if (inputShape.hasStreamingMember(model)) {
                    // wrapping to CachingStream required for test asserts which reads body multiple times
                    writer.write("body: .stream(\$N(data: \$L, isClosed: true)),", SmithyStreamsTypes.Core.BufferedStream, data)
                } else {
                    writer.write("body: .data(\$L),", data)
                }
            }
        } else {
            writer.write("body: nil,")
        }
    }

    private fun renderClientBlock(test: HttpRequestTestCase) {
        val serviceShape = ctx.service
        val clientName = "${ctx.settings.sdkId}Client"

        if (!serviceShape.getTrait(EndpointRuleSetTrait::class.java).isPresent) {
            val host: String? = test.host.orElse(null)
            val url: String = "http://${host ?: "example.com"}"
            writer.write("\nlet config = try await ${clientName}.${clientName}Configuration(endpointResolver: StaticEndpointResolver(endpoint: try \$N(urlString: \$S)))", SmithyHTTPAPITypes.Endpoint, url)
        } else {
            writer.write("\nlet config = try await ${clientName}.${clientName}Configuration()")
        }
        writer.write("config.region = \"us-west-2\"")
        writer.write("config.httpClientEngine = ProtocolTestClient()")
        writer.write("config.idempotencyTokenGenerator = ProtocolTestIdempotencyTokenGenerator()")
        writer.write("let client = ${clientName}(config: config)")
    }

    private fun renderOperationBlock(test: HttpRequestTestCase) {
        operation.input.ifPresent { it ->
            val clientName = "${ctx.settings.sdkId}Client"
            val inputShape = model.expectShape(it)
            model = RecursiveShapeBoxer.transform(model)
            writer.writeInline("\nlet input = ")
                .call {
                    ShapeValueGenerator(model, symbolProvider).writeShapeValueInline(writer, inputShape, test.params)
                }
                .write("")
            val inputSymbol = symbolProvider.toSymbol(inputShape)
            val outputShapeId = operation.output.get()
            val outputShape = model.expectShape(outputShapeId)
            val outputSymbol = symbolProvider.toSymbol(outputShape)
            val outputErrorName = "${operation.toUpperCamelCase()}OutputError"
            writer.addImport(SwiftDependency.SMITHY.target)
            writer.write(
                """
                do {
                    _ = try await client.${operation.toLowerCamelCase()}(input: input)
                } catch TestCheckError.actual(let actual) {
                    ${'$'}{C|}
                }
                writer.write("  .build()")
            }
            val operationStack = "operationStack"
            if (!ctx.settings.useInterceptors) {
                writer.write("var $operationStack = OperationStack<$inputSymbol, $outputSymbol>(id: \"${test.id}\")")
            } else {
                writer.addImport(SwiftDependency.SMITHY_HTTP_API.target)
                writer.write("let builder = OrchestratorBuilder<$inputSymbol, $outputSymbol, SdkHttpRequest, HttpResponse>()")
            }

            operationMiddleware.renderMiddleware(ctx, writer, operation, operationStack, MiddlewareStep.INITIALIZESTEP)
            operationMiddleware.renderMiddleware(ctx, writer, operation, operationStack, MiddlewareStep.BUILDSTEP)
            operationMiddleware.renderMiddleware(ctx, writer, operation, operationStack, MiddlewareStep.SERIALIZESTEP)
            operationMiddleware.renderMiddleware(ctx, writer, operation, operationStack, MiddlewareStep.FINALIZESTEP)
            operationMiddleware.renderMiddleware(ctx, writer, operation, operationStack, MiddlewareStep.DESERIALIZESTEP)

            if (ctx.settings.useInterceptors) {
                writer.write(
                    """
                    let op = builder.attributes(context)
                        .deserialize({ (_, _) in
                            return $outputSymbol()
                        })
                        .executeRequest({ (actual, attributes) in
                            ${'$'}{C|}
                            return HttpResponse(body: .noStream, statusCode: .ok)
                        })
                        .build()

                    _ = try await op.execute(input: input)
                    """.trimIndent(),
                    Runnable { renderBodyAssert(test, inputSymbol, inputShape) }
                )
            } else {
                renderMockDeserializeMiddleware(test, operationStack, inputSymbol, outputSymbol, outputErrorName, inputShape)
                writer.openBlock("_ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler() { (context, request) in ", "})") {
                    writer.write("XCTFail(\"Deserialize was mocked out, this should fail\")")
                    writer.write("throw SmithyTestUtilError(\"Mock handler unexpectedly failed\")")
                }
            }
        }
    }

    private fun resolveHttpMethod(op: OperationShape): String {
        val httpTrait = httpBindingResolver.httpTrait(op)
        return httpTrait.method.toLowerCase()
    }

    private fun renderBodyAssert(test: HttpRequestTestCase, inputSymbol: Symbol, inputShape: Shape) {
        if (test.body.isPresent && test.body.get().isNotBlank()) {
            writer.openBlock(
                "try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in",
                "})"
            ) {
                writer.write("XCTAssertNotNil(actualHttpBody, \"The actual ByteStream is nil\")")
                writer.write("XCTAssertNotNil(expectedHttpBody, \"The expected ByteStream is nil\")")
                val contentType = when (ctx.service.requestWireProtocol) {
                    WireProtocol.XML -> ".xml"
                    WireProtocol.JSON -> ".json"
                    WireProtocol.FORM_URL -> ".formURL"
                }
                writer.write("try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, contentType: \$L)", contentType)
            }
        } else {
            writer.write(
                "try await self.assertEqual(expected, actual)"
            )
        }
    }

    private fun renderExpectedQueryParams(test: HttpRequestTestCase) {
        if (test.queryParams.isNotEmpty()) {
            val queryParams = test.queryParams
            writer.openBlock("queryParams: [")
                .call {
                    queryParams.forEachIndexed { idx, value ->
                        val suffix = if (idx < queryParams.size - 1) "," else ""
                        writer.write("\$S$suffix", value)
                    }
                }
                .closeBlock("],")
        }

        if (test.forbidQueryParams.isNotEmpty()) {
            val queryParams = test.forbidQueryParams
            writer.openBlock("forbiddenQueryParams: [")
                .call {
                    queryParams.forEachIndexed { idx, value ->
                        val suffix = if (idx < queryParams.size - 1) "," else ""
                        writer.write("\$S$suffix", value)
                    }
                }
                .closeBlock("],")
        }

        if (test.requireQueryParams.isNotEmpty()) {
            val queryParams = test.requireQueryParams
            writer.openBlock("requiredQueryParams: [")
                .call {
                    queryParams.forEachIndexed { idx, value ->
                        val suffix = if (idx < queryParams.size - 1) "," else ""
                        writer.write("\$S$suffix", value)
                    }
                }
                .closeBlock("],")
        }
    }

    private fun renderExpectedHeaders(test: HttpRequestTestCase) {
        if (test.headers.isNotEmpty()) {
            writer.openBlock("headers: [")
                .call {
                    for ((idx, hdr) in test.headers.entries.withIndex()) {
                        val suffix = if (idx < test.headers.size - 1) "," else ""
                        writer.write("\$S: \$S$suffix", hdr.key, hdr.value)
                    }
                }
                .closeBlock("],")
        }

        if (test.forbidHeaders.isNotEmpty()) {
            val forbiddenHeaders = test.forbidHeaders
            writer.openBlock("forbiddenHeaders: [")
                .call {
                    forbiddenHeaders.forEachIndexed { idx, value ->
                        val suffix = if (idx < forbiddenHeaders.size - 1) "," else ""
                        writer.write("\$S$suffix", value)
                    }
                }
                .closeBlock("],")
        }

        if (test.requireHeaders.isNotEmpty()) {
            val requiredHeaders = test.requireHeaders
            writer.openBlock("requiredHeaders: [")
                .call {
                    requiredHeaders.forEachIndexed { idx, value ->
                        val suffix = if (idx < requiredHeaders.size - 1) "," else ""
                        writer.write("\$S$suffix", value)
                    }
                }
                .closeBlock("],")
        }
    }

    class Builder : HttpProtocolUnitTestGenerator.Builder<HttpRequestTestCase>() {
        override fun build(): HttpProtocolUnitTestGenerator<HttpRequestTestCase> {
            return HttpProtocolUnitTestRequestGenerator(this)
        }
    }
}
