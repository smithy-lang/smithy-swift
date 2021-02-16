/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.traits.IdempotencyTokenTrait
import software.amazon.smithy.protocoltests.traits.HttpRequestTestCase
import software.amazon.smithy.swift.codegen.IdempotencyTokenMiddlewareGenerator
import software.amazon.smithy.swift.codegen.RecursiveShapeBoxer
import software.amazon.smithy.swift.codegen.ShapeValueGenerator
import software.amazon.smithy.swift.codegen.defaultName
import software.amazon.smithy.swift.codegen.swiftFunctionParameterIndent
import software.amazon.smithy.utils.StringUtils.isBlank

/**
 * Generates HTTP protocol unit tests for `httpRequestTest` cases
 */
open class HttpProtocolUnitTestRequestGenerator protected constructor(builder: Builder) :
    HttpProtocolUnitTestGenerator<HttpRequestTestCase>(builder) {
    override val baseTestClassName = "HttpRequestTestBase"

    override fun renderTestBody(test: HttpRequestTestCase) {
        renderExpectedBlock(test)
        writer.write("")
        renderOperationBlock(test)
    }

    private fun renderExpectedBlock(test: HttpRequestTestCase) {
        writer.openBlock("let expected = buildExpectedHttpRequest(")
            .write("method: .${test.method.toLowerCase()},")
            .write("path: \$S,", test.uri)
            .call { renderExpectedHeaders(test) }
            .call { renderExpectedQueryParams(test) }
            .call { renderExpectedBody(test) }
            .write("host: host")
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
            // Default to bytes comparison
            var requestEncoder = "JSONEncoder()"
            var bodyAssertMethod = "assertEqualHttpBodyData"

            if (test.bodyMediaType.isPresent) {
                val bodyMediaType = test.bodyMediaType.get()
                when (bodyMediaType.toLowerCase()) {
                    "application/json" -> {
                        requestEncoder = "JSONEncoder()"
                        bodyAssertMethod = "assertEqualHttpBodyJSONData"
                    }
                    "application/xml" -> TODO("xml assertion not implemented yet")
                    "application/x-www-form-urlencoded" -> TODO("urlencoded form assertion not implemented yet")
                }
            }
            writer.write("let deserializeMiddleware = expectation(description: \"deserializeMiddleware\")\n")
            // TODO:: handle streaming inputs
            // isStreamingRequest = inputShape.asStructureShape().get().hasStreamingMember(model)
            writer.writeInline("\nlet input = ")
                .call {
                    ShapeValueGenerator(model, symbolProvider).writeShapeValueInline(writer, inputShape, test.params)
                }
                .write("")

            val inputSymbol = symbolProvider.toSymbol(inputShape)
            val outputShapeId = operation.output.get()
            val outputShape = model.expectShape(outputShapeId)
            val outputSymbol = symbolProvider.toSymbol(outputShape)
            val outputErrorName = "${operation.defaultName()}Error"
            val hasHttpBody = inputShape.members().filter { it.isInHttpBody() }.count() > 0

            writer.write("let encoder = \$L", requestEncoder)
            writer.write("encoder.dateEncodingStrategy = .secondsSince1970")
            writer.write("let context = HttpContextBuilder()")
            val idempotentMember = inputShape.members().firstOrNull() { it.hasTrait(IdempotencyTokenTrait::class.java) }
            val hasIdempotencyTokenTrait = idempotentMember != null
            writer.swiftFunctionParameterIndent {
                writer.write("  .withEncoder(value: encoder)")
                if (hasIdempotencyTokenTrait) {
                    writer.write("  .withIdempotencyTokenGenerator(value: QueryIdempotencyTestTokenGenerator())")
                }
                writer.write("  .build()")
            }
            val operationStack = "operationStack"
            val letVarOperationStack = if (hasIdempotencyTokenTrait) "var" else "let"
            writer.write("$letVarOperationStack $operationStack = OperationStack<$inputSymbol, $outputSymbol, $outputErrorName>(id: \"${test.id}\")")
            renderSerializeMiddleware(test, operationStack, inputSymbol, outputSymbol, outputErrorName, hasHttpBody)
            renderBuildMiddleware(test, operationStack, outputSymbol, outputErrorName, hasHttpBody)
            renderMockDeserializeMiddleware(test, operationStack, outputSymbol, outputErrorName, bodyAssertMethod)
            if (hasIdempotencyTokenTrait) {

                IdempotencyTokenMiddlewareGenerator(writer, idempotentMember!!.memberName, operationStack, outputSymbol.name, outputErrorName).renderIdempotencyMiddleware()
            }

            writer.openBlock("_ = operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in ", "})") {
                writer.write("XCTFail(\"Deserialize was mocked out, this should fail\")")
                writer.write("return .failure(try! MockMiddlewareError(httpResponse: HttpResponse(body: .none, statusCode: .badRequest)))")
            }
            writer.write("wait(for: [deserializeMiddleware], timeout: 0.3)")
        }
    }

    private fun renderSerializeMiddleware(
        test: HttpRequestTestCase,
        operationStack: String,
        inputSymbol: Symbol,
        outputSymbol: Symbol,
        outputErrorName: String,
        hasHttpBody: Boolean
    ) {
        writer.write("$operationStack.serializeStep.intercept(position: .before, middleware: ${inputSymbol.name}HeadersMiddleware())")
        writer.write("$operationStack.serializeStep.intercept(position: .before, middleware: ${inputSymbol.name}QueryItemMiddleware())")
        if (hasHttpBody) {
            writer.write("$operationStack.serializeStep.intercept(position: .before, middleware: ${inputSymbol.name}BodyMiddleware())")
        }

        if (test.headers.keys.contains("Content-Type")) {
            val contentType = test.headers["Content-Type"]
            writer.write("$operationStack.serializeStep.intercept(position: .before, middleware: ContentTypeMiddleware<${inputSymbol.name}, $outputSymbol, $outputErrorName>(contentType: \"${contentType}\"))")
        }
    }

    private fun renderBuildMiddleware(test: HttpRequestTestCase, operationStack: String, outputSymbol: Symbol, outputErrorName: String, hasHttpBody: Boolean) {
        if (hasHttpBody) {
            writer.write("$operationStack.buildStep.intercept(position: .before, middleware: ContentLengthMiddleware<$outputSymbol, $outputErrorName>())")
        }
    }
    private fun renderMockDeserializeMiddleware(test: HttpRequestTestCase, operationStack: String, outputSymbol: Symbol, outputErrorName: String, bodyAssertMethod: String) {

        writer.write("$operationStack.deserializeStep.intercept(position: .after,")
        writer.write("             middleware: MockDeserializeMiddleware<$outputSymbol, $outputErrorName>(")
        writer.openBlock("                     id: \"TestDeserializeMiddleware\"){ context, actual in", "})") {
            renderQueryAsserts(test)
            renderHeaderAsserts(test)
            renderBodyAssert(test, bodyAssertMethod)
            writer.write("let response = HttpResponse(body: HttpBody.none, statusCode: .ok)")
            writer.write("let mockOutput = try! $outputSymbol(httpResponse: response, decoder: nil)")
            writer.write("let output = OperationOutput<$outputSymbol, $outputErrorName>(httpResponse: response, output: mockOutput)")
            writer.write("deserializeMiddleware.fulfill()")
            writer.write("return .success(output)")
        }
    }

    private fun renderQueryAsserts(test: HttpRequestTestCase) {
        // assert that forbidden Query Items do not exist
        if (test.forbidQueryParams.isNotEmpty()) {
            writer.write("let forbiddenQueryParams = [\"${test.forbidQueryParams.joinToString(separator = ", ")}\"]")
            writer.write("// assert forbidden query params do not exist")
            writer.openBlock("for forbiddenQueryParam in forbiddenQueryParams {", "}") {
                writer.openBlock("XCTAssertFalse(", ")") {
                    writer.write("self.queryItemExists(forbiddenQueryParam, in: actual.endpoint.queryItems),")
                    writer.write("\"Forbidden Query:\\(forbiddenQueryParam) exists in query items\"")
                }
            }
        }

        // assert that required Query Items do exist
        if (test.requireQueryParams.isNotEmpty()) {
            writer.write("let requiredQueryParams = [\"${test.requireQueryParams.joinToString(separator = ", ")}\"]")
            writer.write("// assert required query params do exist")
            writer.openBlock("for requiredQueryParam in requiredQueryParams {", "}") {
                writer.openBlock("XCTAssertTrue(", ")") {
                    writer.write("self.queryItemExists(requiredQueryParam, in: actual.endpoint.queryItems),")
                    writer.write("\"Required Query:\\(requiredQueryParam) does not exist in query items\"")
                }
            }
        }
    }

    private fun renderHeaderAsserts(test: HttpRequestTestCase) {
        // assert that forbidden headers do not exist
        if (test.forbidHeaders.isNotEmpty()) {
            writer.write("let forbiddenHeaders = [\"${test.forbidHeaders.joinToString(separator = ", ")}\"]")
            writer.write("// assert forbidden headers do not exist")
            writer.openBlock("for forbiddenHeader in forbiddenHeaders {", "}") {
                writer.openBlock("XCTAssertFalse(", ")") {
                    writer.write("self.headerExists(forbiddenHeader, in: actual.headers.headers),")
                    writer.write("\"Forbidden Header:\\(forbiddenHeader) exists in headers\"")
                }
            }
        }
        // assert that required Headers do exist
        if (test.requireHeaders.isNotEmpty()) {
            writer.write("let requiredHeaders = [\"${test.requireHeaders.joinToString(separator = ", ")}\"]")
            writer.write("// assert required headers do exist")
            writer.openBlock("for requiredHeader in requiredHeaders {", "}") {
                writer.openBlock("XCTAssertTrue(", ")") {
                    writer.write("self.headerExists(requiredHeader, in: actual.headers.headers),")
                    writer.write("\"Required Header:\\(requiredHeader) does not exist in headers\"")
                }
            }
        }
    }

    private fun renderBodyAssert(test: HttpRequestTestCase, bodyAssertMethod: String) {
        if (test.body.isPresent && !test.body.get().isBlank() && test.body.get() != "{}") {
            writer.openBlock(
                "self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in",
                "})"
            ) {
                writer.write("XCTAssertNotNil(actualHttpBody, \"The actual HttpBody is nil\")")
                writer.write("XCTAssertNotNil(expectedHttpBody, \"The expected HttpBody is nil\")")
                writer.write("self.$bodyAssertMethod(expectedHttpBody!, actualHttpBody!)")
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

    private fun renderExpectedQueryParams(test: HttpRequestTestCase) {
        if (test.queryParams.isEmpty()) {
            writer.write("queryParams: [String](),") // pass empty array if no query params
        } else {
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
    }

    private fun renderExpectedHeaders(test: HttpRequestTestCase) {
        if (test.headers.isEmpty()) {
            writer.write("headers: [String: String](),") // pass empty dictionary if no headers
        } else {
            writer.openBlock("headers: [")
                .call {
                    for ((idx, hdr) in test.headers.entries.withIndex()) {
                        val suffix = if (idx < test.headers.size - 1) "," else ""
                        writer.write("\$S: \$S$suffix", hdr.key, hdr.value)
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
