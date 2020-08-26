/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.protocoltests.traits.HttpRequestTestCase
import software.amazon.smithy.swift.codegen.ShapeValueGenerator

/**
 * Generates HTTP protocol unit tests for `httpRequestTest` cases
 */
open class HttpProtocolUnitTestRequestGenerator protected constructor(builder: Builder) :
    HttpProtocolUnitTestGenerator<HttpRequestTestCase>(builder) {

    override fun openTestFunctionBlock(): String = "= httpRequestTest {"

    override fun renderTestBody(test: HttpRequestTestCase) {
        renderExpectedBlock(test)
        writer.write("")
        renderOperationBlock(test)
    }

    private fun renderExpectedBlock(test: HttpRequestTestCase) {
        writer.openBlock("let expected = buildExpectedHttpRequest(")
            .write("method: .${test.method.toLowerCase()}")
            .write("path: \"\$S\"", test.uri)
            .call { renderExpectedHeaders(test) }
            .call { renderExpectedQueryParams(test) }
            // TODO:: Replace host appropriately
            .write("host: \"my-api.us-east-2.amazonaws.com\"")
            .call {
                test.body.ifPresent { body ->
                    if (!body.isBlank()) {
                        writer.write("body: \"\"\"\$L\"\"\"", body)
                    }
                }
            }
            .closeBlock(")")
    }

    private fun renderOperationBlock(test: HttpRequestTestCase) {
        operation.input.ifPresent {
            val inputShape = model.expectShape(it)
            var requestEncoderInstance = ""
            var bodyAssertClosure = ""
            if (test.bodyMediaType.isPresent) {
                val bodyMediaType = test.bodyMediaType.get()
                val compareFunc = when (bodyMediaType.toLowerCase()) {
                    "application/json" -> "::assertJsonBodiesEqual"
                    "application/xml" -> TODO("xml assertion not implemented yet")
                    "application/x-www-form-urlencoded" -> TODO("urlencoded form assertion not implemented yet")
                    // compare reader bytes
                    else -> "::assertBytesEqual"
                }
            }
            else {

            }
            // TODO:: handle streaming inputs
            // isStreamingRequest = inputShape.asStructureShape().get().hasStreamingMember(model)

            // invoke the DSL builder for the input type
            writer.writeInline("\nlet input = ")
                .indent()
                .call {
                    ShapeValueGenerator(model, symbolProvider).writeShapeValueInline(writer, inputShape, test.params)
                }
                .dedent()
                .write("")

            writer.write("var actual = input.buildHttpRequest(method: .${test.method.toLowerCase()}, path: \"\$S\"", test.uri)
            writer.openBlock("do {")
                .write("_ = try encoder.encodeHttpRequest(input, currentHttpRequest: &actual)")
                .closeBlock("} catch let err {")
                .indent()
                .write("XCTFail(\"Failed to encode the input. Error description: \\(err)\")")
                .dedent()
                .write("}")
        }
    }

    private fun renderExpectedQueryParams(test: HttpRequestTestCase) {
        if (test.queryParams.isEmpty()) return

        val queryParams = test.queryParams
            .map {
                val kvPair = it.split("=", limit = 2)
                val value = kvPair.getOrNull(1) ?: ""
                Pair(kvPair[0], value)
            }

        writer.openBlock("queryParams = listOf(")
            .call {
                queryParams.forEachIndexed { idx, (key, value) ->
                    val suffix = if (idx < queryParams.size - 1) "," else ""
                    writer.write("\$S to \$S$suffix", key, value)
                }
            }
            .closeBlock(")")
    }

    private fun renderExpectedHeaders(test: HttpRequestTestCase) {
        if (test.headers.isEmpty()) return
        writer.openBlock("headers = mapOf(")
            .call {
                for ((idx, hdr) in test.headers.entries.withIndex()) {
                    val suffix = if (idx < test.headers.size - 1) "," else ""
                    writer.write("\$S to \$S$suffix", hdr.key, hdr.value)
                }
            }
            .closeBlock(")")
    }

    private fun renderExpectedListOfParams(name: String, params: List<String>) {
        if (params.isEmpty()) return
        val joined = params.joinToString(
            separator = ",",
            transform = { "\"$it\"" }
        )
        writer.write("$name = listOf($joined)")
    }

    class Builder : HttpProtocolUnitTestGenerator.Builder<HttpRequestTestCase>() {
        override fun build(): HttpProtocolUnitTestGenerator<HttpRequestTestCase> {
            return HttpProtocolUnitTestRequestGenerator(this)
        }
    }
}
