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
            .write("method: .${test.method.toLowerCase()},")
            .write("path: \$S,", test.uri)
            .call { renderExpectedHeaders(test) }
            .call { renderExpectedQueryParams(test) }
            .call { renderExpectedBody(test) }
            .write("host: host")
            .closeBlock(")")
    }

    private fun renderExpectedBody( test: HttpRequestTestCase) {
        if(!test.body.isPresent) {
            writer.write("body: nil,")
        } else {
            test.body.ifPresent { body ->
                if (!body.isBlank()) {
                    writer.write("body: \"\"\"\n\$L\n\"\"\",", body)
                }
            }
        }
    }

    private fun renderOperationBlock(test: HttpRequestTestCase) {
        operation.input.ifPresent {
            val inputShape = model.expectShape(it)
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

            // TODO:: handle streaming inputs
            // isStreamingRequest = inputShape.asStructureShape().get().hasStreamingMember(model)

            // invoke the DSL builder for the input type
            writer.writeInline("\nlet input = ")
                .call {
                    ShapeValueGenerator(model, symbolProvider).writeShapeValueInline(writer, inputShape, test.params)
                }
                .write("")

            writer.write("var actual = input.buildHttpRequest(method: .${test.method.toLowerCase()}, path: \$S)", test.uri)
            if(!test.body.isEmpty) { //if body is not empty we will need to serialize it
                writer.openBlock("do {")
                    .write("_ = try $requestEncoder.encodeHttpRequest(input, currentHttpRequest: &actual)")
                    .closeBlock("} catch let err {")
                    .indent()
                    .write("XCTFail(\"Failed to encode the input. Error description: \\(err)\")")
                    .dedent()
                    .write("}")
            }

            // assert that forbidden Query Items do not exist
            if (test.forbidQueryParams.isNotEmpty()) {
                writer.write("let forbiddenQueryParams = [\"${test.forbidQueryParams.joinToString(separator = ", ")}\"]")
                writer.write("// assert forbidden query params do not exist")
                writer.openBlock("for forbiddenQueryParam in forbiddenQueryParams {", "}") {
                    writer.openBlock("XCTAssertFalse(", ")") {
                        writer.write("queryItemExists(forbiddenQueryParam, in: actual.endpoint.queryItems),")
                        writer.write("\"Forbidden Query:\\(forbiddenQueryParam) exists in query items\"")
                    }
                }
            }

            // assert that forbidden headers do not exist
            if (test.forbidHeaders.isNotEmpty()) {
                writer.write("let forbiddenHeaders = [${test.forbidHeaders.joinToString(separator = ", ")}]")
                writer.write("// assert forbidden headers do not exist")
                writer.openBlock("for forbiddenHeader in forbiddenHeaders {", "}") {
                    writer.openBlock("XCTAssertFalse(", ")") {
                        writer.write("headerExists(forbiddenHeader, in: actual.headers.headers),")
                        writer.write("\"Forbidden Header:\\(forbiddenHeader) exists in headers\"")
                    }
                }
            }

            // assert that required Query Items do exist
            if (test.requireQueryParams.isNotEmpty()) {
                writer.write("let requiredQueryParams = [${test.requireQueryParams.joinToString(separator = ", ")}]")
                writer.write("// assert required query params do exist")
                writer.openBlock("for requiredQueryParam in requiredQueryParams {", "}") {
                    writer.openBlock("XCTAssertTrue(", ")") {
                        writer.write("queryItemExists(requiredQueryParam, in: actual.endpoint.queryItems),")
                        writer.write("\"Required Query:\\(requiredQueryParam) does not exist in query items\"")
                    }
                }
            }

            // assert that required Headers do exist
            if (test.requireHeaders.isNotEmpty()) {
                writer.write("let requiredHeaders = [${test.requireHeaders.joinToString(separator = ", ")}]")
                writer.write("// assert required headers do exist")
                writer.openBlock("for requiredHeader in requiredHeaders {", "}") {
                    writer.openBlock("XCTAssertTrue(", ")") {
                        writer.write("headerExists(requiredHeader, in: actual.headers.headers),")
                        writer.write("\"Required Header:\\(requiredHeader) does not exist in headers\"")
                    }
                }
            }

            if (test.body.isPresent) {
                writer.openBlock("assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in", "})") {
                    writer.write("XCTAssertNotNil(actualHttpBody, \"The actual HttpBody is nil\")")
                    writer.write("XCTAssertNotNil(expectedHttpBody, \"The expected HttpBody is nil\")")
                    writer.write("$bodyAssertMethod(expectedHttpBody!, actualHttpBody!)")
                }
            }
        }
    }

    private fun renderExpectedQueryParams(test: HttpRequestTestCase) {
        if (test.queryParams.isEmpty()) {
            writer.write("queryParams: [String](),") //pass empty array if no query params
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
            writer.write("headers: [String: String](),") //pass empty dictionary if no headers
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
