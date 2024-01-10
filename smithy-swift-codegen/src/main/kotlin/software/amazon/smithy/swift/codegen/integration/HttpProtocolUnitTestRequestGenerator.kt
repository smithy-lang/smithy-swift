/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.HttpHeaderTrait
import software.amazon.smithy.model.traits.HttpQueryTrait
import software.amazon.smithy.model.traits.IdempotencyTokenTrait
import software.amazon.smithy.protocoltests.traits.HttpRequestTestCase
import software.amazon.smithy.swift.codegen.ShapeValueGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.hasStreamingMember
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.ResponseClosureUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.WireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.requestWireProtocol
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer
import software.amazon.smithy.swift.codegen.model.toUpperCamelCase
import software.amazon.smithy.swift.codegen.swiftFunctionParameterIndent

open class HttpProtocolUnitTestRequestGenerator protected constructor(builder: Builder) :
    HttpProtocolUnitTestGenerator<HttpRequestTestCase>(builder) {
    override val baseTestClassName = "HttpRequestTestBase"

    override fun renderTestBody(test: HttpRequestTestCase) {
        renderExpectedBlock(test)
        writer.write("")
        renderOperationBlock(test)
    }

    private fun renderExpectedBlock(test: HttpRequestTestCase) {
        var resolvedHostValue = test.resolvedHost?.let { it } ?: run { "nil" }
        writer.write("let urlPrefix = urlPrefixFromHost(host: \$S)", test.host)
        writer.write("let hostOnly = hostOnlyFromHost(host: \$S)", test.host)
        writer.openBlock("let expected = buildExpectedHttpRequest(")
            .write("method: .${test.method.toLowerCase()},")
            .write("path: \$S,", test.uri)
            .call { renderExpectedHeaders(test) }
            .call { renderExpectedQueryParams(test) }
            .call { renderExpectedBody(test) }
            .write("host: \$S,", test.host)
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
                    writer.write("body: .stream(BufferedStream(data: \$L, isClosed: true)),", data)
                } else {
                    writer.write("body: .data(\$L),", data)
                }
            }
        } else {
            writer.write("body: nil,")
        }
    }

    private fun renderOperationBlock(test: HttpRequestTestCase) {
        operation.input.ifPresent { it ->
            val inputShape = model.expectShape(it)
            model = RecursiveShapeBoxer.transform(model)

            val decoderProperty = httpProtocolCustomizable.getClientProperties().filterIsInstance<HttpResponseDecoder>().firstOrNull()
            decoderProperty?.renderInstantiation(writer)
            decoderProperty?.renderConfiguration(writer)

            writer.writeInline("\nlet input = ")
                .call {
                    ShapeValueGenerator(model, symbolProvider).writeShapeValueInline(writer, inputShape, test.params)
                }
                .write("")
            val encoderProperty = httpProtocolCustomizable.getClientProperties().filterIsInstance<HttpRequestEncoder>().firstOrNull()
            encoderProperty?.renderInstantiation(writer)
            encoderProperty?.renderConfiguration(writer)

            val inputSymbol = symbolProvider.toSymbol(inputShape)
            val outputShapeId = operation.output.get()
            val outputShape = model.expectShape(outputShapeId)
            val outputSymbol = symbolProvider.toSymbol(outputShape)
            val outputErrorName = "${operation.toUpperCamelCase()}OutputError"

            writer.write("let context = HttpContextBuilder()")
            val idempotentMember = inputShape.members().firstOrNull() { it.hasTrait(IdempotencyTokenTrait::class.java) }
            val hasIdempotencyTokenTrait = idempotentMember != null
            val httpMethod = resolveHttpMethod(operation)
            writer.swiftFunctionParameterIndent {
                writer.write("  .withEncoder(value: encoder)")
                writer.write("  .withMethod(value: .$httpMethod)")
                if (hasIdempotencyTokenTrait) {
                    writer.write("  .withIdempotencyTokenGenerator(value: QueryIdempotencyTestTokenGenerator())")
                }
                writer.write("  .build()")
            }
            val operationStack = "operationStack"
            writer.write("var $operationStack = OperationStack<$inputSymbol, $outputSymbol>(id: \"${test.id}\")")

            operationMiddleware.renderMiddleware(ctx, writer, operation, operationStack, MiddlewareStep.INITIALIZESTEP)
            operationMiddleware.renderMiddleware(ctx, writer, operation, operationStack, MiddlewareStep.BUILDSTEP)
            operationMiddleware.renderMiddleware(ctx, writer, operation, operationStack, MiddlewareStep.SERIALIZESTEP)
            operationMiddleware.renderMiddleware(ctx, writer, operation, operationStack, MiddlewareStep.FINALIZESTEP)
            operationMiddleware.renderMiddleware(ctx, writer, operation, operationStack, MiddlewareStep.DESERIALIZESTEP)

            renderMockDeserializeMiddleware(test, operationStack, inputSymbol, outputSymbol, outputErrorName, inputShape)

            writer.openBlock("_ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler() { (context, request) in ", "})") {
                writer.write("XCTFail(\"Deserialize was mocked out, this should fail\")")
                writer.write("throw SmithyTestUtilError(\"Mock handler unexpectedly failed\")")
            }
        }
    }

    private fun resolveHttpMethod(op: OperationShape): String {
        val httpTrait = httpBindingResolver.httpTrait(op)
        return httpTrait.method.toLowerCase()
    }

    private fun renderMockDeserializeMiddleware(
        test: HttpRequestTestCase,
        operationStack: String,
        inputSymbol: Symbol,
        outputSymbol: Symbol,
        outputErrorName: String,
        inputShape: Shape
    ) {
        writer.openBlock("\$L.deserializeStep.intercept(", ")", operationStack) {
            writer.write("position: .after,")
            writer.openBlock("middleware: MockDeserializeMiddleware<\$N>(", ")", outputSymbol) {
                writer.write("id: \"TestDeserializeMiddleware\",")
                val responseClosure = ResponseClosureUtils(ctx, writer, operation).render()
                writer.write("responseClosure: \$L,", responseClosure)
                writer.openBlock("callback: { context, actual in", "}") {
                    renderBodyAssert(test, inputSymbol, inputShape)
                    writer.write("return OperationOutput(httpResponse: HttpResponse(body: ByteStream.noStream, statusCode: .ok), output: \$N())", outputSymbol)
                }
            }
        }
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

    private fun determineBodyComparisonStrategy(test: HttpRequestTestCase): ((SwiftWriter, HttpRequestTestCase, Symbol, Shape, String, String) -> Unit) {
        httpProtocolCustomizable.customRenderBodyComparison(test)?.let {
            return it
        } ?: run {
            return this::renderBodyComparison
        }
    }

    private fun renderBodyForHttpPayload(writer: SwiftWriter, symbol: Symbol, expectedData: String, actualData: String) {
//        writer.openBlock("do {", "} catch {") {
//            writer.write("let expectedObj = try decoder.decode($symbol.self, from: $expectedData)")
//            writer.write("let actualObj = try decoder.decode($symbol.self, from: $actualData)")
//            writer.write("XCTAssertEqual(expectedObj, actualObj)")
//        }
//        writer.indent()
//        writer.write("XCTFail(\"Failed to verify body \\(error)\")")
//        writer.dedent()
//        writer.write("}")
    }

    private fun renderBodyComparison(writer: SwiftWriter, test: HttpRequestTestCase, symbol: Symbol, shape: Shape, expectedData: String, actualData: String) {
//        writer.openBlock("do {", "} catch {") {
//            writer.write("let expectedObj = try decoder.decode(${symbol}Body.self, from: $expectedData)")
//            writer.write("let actualObj = try decoder.decode(${symbol}Body.self, from: $actualData)")
//            renderAssertions(test, shape)
//        }
//        writer.indent()
//        writer.write("XCTFail(\"Failed to verify body \\(error)\")")
//        writer.dedent()
//        writer.write("}")
    }

    private fun renderDataComparison(writer: SwiftWriter, expectedData: String, actualData: String) {
        val assertionMethod = "XCTAssertJSONDataEqual"
        writer.write("\$L(\$L, \$L, \"Some error message\")", assertionMethod, actualData, expectedData)
    }

    protected open fun renderAssertions(test: HttpRequestTestCase, outputShape: Shape) {
        val members = outputShape.members().filterNot { it.hasTrait(HttpQueryTrait::class.java) }
            .filterNot { it.hasTrait(HttpHeaderTrait::class.java) }
        renderMemberAssertions(writer, test, members, model, symbolProvider, "expectedObj", "actualObj")
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
