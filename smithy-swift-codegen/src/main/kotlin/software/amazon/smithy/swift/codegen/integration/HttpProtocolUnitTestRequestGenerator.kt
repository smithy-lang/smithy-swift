/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.traits.HttpHeaderTrait
import software.amazon.smithy.model.traits.HttpPayloadTrait
import software.amazon.smithy.model.traits.HttpQueryTrait
import software.amazon.smithy.model.traits.IdempotencyTokenTrait
import software.amazon.smithy.protocoltests.traits.HttpRequestTestCase
import software.amazon.smithy.swift.codegen.ShapeValueGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer
import software.amazon.smithy.swift.codegen.model.capitalizedName
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
        //var hostVariable = "host"
        //writer.write("let host = \$S", test.host)
//        test.resolvedHost?.let {
  //          hostVariable = "resolvedHost"
  //          writer.write("let resolvedHost = \$S", it)
//        }
        writer.openBlock("let expected = buildExpectedHttpRequest(")
            .write("method: .${test.method.toLowerCase()},")
            .write("path: \$S,", test.uri)
            .call { renderExpectedHeaders(test) }
            .call { renderExpectedQueryParams(test) }
            .call { renderExpectedBody(test) }
//            .write("host: ${hostVariable}")
            .closeBlock(")")
    }

    private fun renderExpectedBody(test: HttpRequestTestCase) {
        if (test.body.isEmpty) {
            writer.write("body: nil,")
        } else {
            test.body.ifPresent { body ->
                when {
                    !body.isBlank() && body != "{}" -> writer.write(
                        "body: \"\"\"\n\$L\n\"\"\",",
                        body.replace("\\\"", "\\\\\"")
                    )
                    body == "{}" -> writer.write("body: nil,")
                    else -> writer.write("body: nil,")
                }
            }
        }
    }

    private fun renderOperationBlock(test: HttpRequestTestCase) {
        operation.input.ifPresent { it ->
            val inputShape = model.expectShape(it)
            model = RecursiveShapeBoxer.transform(model)
            writer.write("let deserializeMiddleware = expectation(description: \"deserializeMiddleware\")\n")
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
            val outputErrorName = "${operation.capitalizedName()}OutputError"

            writer.write("let context = HttpContextBuilder()")
            val idempotentMember = inputShape.members().firstOrNull() { it.hasTrait(IdempotencyTokenTrait::class.java) }
            val hasIdempotencyTokenTrait = idempotentMember != null
            writer.swiftFunctionParameterIndent {
                writer.write("  .withEncoder(value: encoder)")
                //writer.write("  .withHost(value: host)")
                if (hasIdempotencyTokenTrait) {
                    writer.write("  .withIdempotencyTokenGenerator(value: QueryIdempotencyTestTokenGenerator())")
                }
                writer.write("  .build()")
            }
            val operationStack = "operationStack"
            writer.write("var $operationStack = OperationStack<$inputSymbol, $outputSymbol, $outputErrorName>(id: \"${test.id}\")")

            operationMiddleware.renderMiddleware(writer, operation, operationStack, MiddlewareStep.INITIALIZESTEP)
            operationMiddleware.renderMiddleware(writer, operation, operationStack, MiddlewareStep.BUILDSTEP)
            operationMiddleware.renderMiddleware(writer, operation, operationStack, MiddlewareStep.SERIALIZESTEP)
            operationMiddleware.renderMiddleware(writer, operation, operationStack, MiddlewareStep.FINALIZESTEP)
            operationMiddleware.renderMiddleware(writer, operation, operationStack, MiddlewareStep.DESERIALIZESTEP)

            renderMockDeserializeMiddleware(test, operationStack, inputSymbol, outputSymbol, outputErrorName, inputShape)

            writer.openBlock("_ = operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in ", "})") {
                writer.write("XCTFail(\"Deserialize was mocked out, this should fail\")")
                writer.write("let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)")
                writer.write("let serviceError = try! $outputErrorName(httpResponse: httpResponse)")
                writer.write("return .failure(.service(serviceError, httpResponse))")
            }
            writer.write("wait(for: [deserializeMiddleware], timeout: 0.3)")
        }
    }

    private fun renderMockDeserializeMiddleware(
        test: HttpRequestTestCase,
        operationStack: String,
        inputSymbol: Symbol,
        outputSymbol: Symbol,
        outputErrorName: String,
        inputShape: Shape
    ) {

        writer.write("$operationStack.deserializeStep.intercept(position: .after,")
        writer.write("             middleware: MockDeserializeMiddleware<$outputSymbol, $outputErrorName>(")
        writer.openBlock("                     id: \"TestDeserializeMiddleware\"){ context, actual in", "})") {
            renderBodyAssert(test, inputSymbol, inputShape)
            writer.write("let response = HttpResponse(body: HttpBody.none, statusCode: .ok)")
            writer.write("let mockOutput = try! $outputSymbol(httpResponse: response, decoder: nil)")
            writer.write("let output = OperationOutput<$outputSymbol>(httpResponse: response, output: mockOutput)")
            writer.write("deserializeMiddleware.fulfill()")
            writer.write("return .success(output)")
        }
    }

    private fun renderBodyAssert(test: HttpRequestTestCase, inputSymbol: Symbol, inputShape: Shape) {
        if (test.body.isPresent && test.body.get().isNotBlank() && test.body.get() != "{}") {
            writer.openBlock(
                "self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in",
                "})"
            ) {
                writer.write("XCTAssertNotNil(actualHttpBody, \"The actual HttpBody is nil\")")
                writer.write("XCTAssertNotNil(expectedHttpBody, \"The expected HttpBody is nil\")")
                val expectedData = "expectedData"
                val actualData = "actualData"
                writer.openBlock("self.genericAssertEqualHttpBodyData(expectedHttpBody!, actualHttpBody!) { $expectedData, $actualData in ", "}") {
                    val httpPayloadShape = inputShape.members().firstOrNull { it.hasTrait(HttpPayloadTrait::class.java) }

                    httpPayloadShape?.let {
                        val target = model.expectShape(it.target)
                        when (target.type) {
                            ShapeType.STRUCTURE, ShapeType.UNION, ShapeType.DOCUMENT -> {
                                val nestedSymbol = symbolProvider.toSymbol(target)
                                renderBodyForHttpPayload(writer, nestedSymbol, expectedData, actualData)
                            }
                            else -> writer.write("XCTAssertEqual($expectedData, $actualData)")
                        }
                    } ?: run {
                        val bodyComparisonStrategy = determineBodyComparisonStrategy(test)
                        bodyComparisonStrategy(writer, test, inputSymbol, inputShape, expectedData, actualData)
                    }
                }
            }
        } else {
            writer.openBlock(
                "self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in",
                "})"
            ) {
                writer.write("XCTAssert(actualHttpBody == HttpBody.none, \"The actual HttpBody is not none as expected\")")
                writer.write("XCTAssert(expectedHttpBody == HttpBody.none, \"The expected HttpBody is not none as expected\")")
            }
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
        writer.openBlock("do {", "} catch let err {") {
            writer.write("let expectedObj = try decoder.decode($symbol.self, from: $expectedData)")
            writer.write("let actualObj = try decoder.decode($symbol.self, from: $actualData)")
            writer.write("XCTAssertEqual(expectedObj, actualObj)")
        }
        writer.indent()
        writer.write("XCTFail(\"Failed to verify body \\(err)\")")
        writer.dedent()
        writer.write("}")
    }

    private fun renderBodyComparison(writer: SwiftWriter, test: HttpRequestTestCase, symbol: Symbol, shape: Shape, expectedData: String, actualData: String) {
        writer.openBlock("do {", "} catch let err {") {
            writer.write("let expectedObj = try decoder.decode(${symbol}Body.self, from: $expectedData)")
            writer.write("let actualObj = try decoder.decode(${symbol}Body.self, from: $actualData)")
            renderAssertions(test, shape)
        }
        writer.indent()
        writer.write("XCTFail(\"Failed to verify body \\(err)\")")
        writer.dedent()
        writer.write("}")
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
