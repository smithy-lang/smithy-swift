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

import software.amazon.smithy.model.shapes.*
import software.amazon.smithy.model.traits.HttpQueryTrait
import software.amazon.smithy.protocoltests.traits.HttpResponseTestCase
import software.amazon.smithy.swift.codegen.ShapeValueGenerator

/**
 * Generates HTTP protocol unit tests for `httpResponseTest` cases
 */
open class HttpProtocolUnitTestResponseGenerator protected constructor(builder: Builder) :
    HttpProtocolUnitTestGenerator<HttpResponseTestCase>(builder) {

    protected open val outputShape: Shape?
        get() {
            return operation.output.map {
                model.expectShape(it)
            }.orElse(null)
        }

    override fun renderTestBody(test: HttpResponseTestCase) {
        outputShape?.let {
            val symbol = symbolProvider.toSymbol(it)
            renderActualOutput(test, symbol.name)
            writer.write("")
            renderExpectedOutput(test, it)
            renderAssertions(test, it)
        }
    }

    private fun renderActualOutput(test: HttpResponseTestCase, outputStructName: String) {
        var responseDecoder = ""
        writer.openBlock("let httpResponse = buildHttpResponse(")
            .call {
                writer
                    .write("code: ${test.code},")
                    .call { renderHeadersInHttpResponse(test) }
                    .call {
                        test.body.ifPresent { body ->
                            if (body.isNotBlank() && body.isNotEmpty()) {
                                if (test.bodyMediaType.isPresent) {
                                    val bodyMediaType = test.bodyMediaType.get()
                                    responseDecoder = when (bodyMediaType.toLowerCase()) {
                                        "application/json" -> "JSONDecoder()"
                                        "application/xml" -> "XMLDecoder()"
                                        "application/x-www-form-urlencoded" -> TODO("urlencoded form assertion not implemented yet")
                                        else -> "JSONDecoder"
                                    }
                                }
                                // TODO:: handle streaming case?
                                writer.write("content: ResponseType.data(\"\"\"\n\$L\n\"\"\".data(using: .utf8)),", body)
                            }
                        }
                    }
                    .write("host: host")
            }
            .closeBlock(")")
        if (responseDecoder.isNotBlank()) {
            writer.write("let actual = $outputStructName(httpResponse: httpResponse, decoder: $responseDecoder)")
        } else {
            writer.write("let actual = $outputStructName(httpResponse: httpResponse)")
        }
    }

    private fun renderExpectedOutput(test: HttpResponseTestCase, outputShape: Shape) {
        // invoke the DSL builder for the input type
        writer.writeInline("\nlet expected = ")
            .call {
                ShapeValueGenerator(model, symbolProvider).writeShapeValueInline(writer, outputShape, test.params)
            }
            .write("")
    }

    private fun renderAssertions(test: HttpResponseTestCase, outputShape: Shape) {
        val members = outputShape.members()
        for (member in members) {
            if (!member.hasTrait(HttpQueryTrait::class.java)) {
                val expectedMemberName = "expected.${symbolProvider.toMemberName(member)}"
                val actualMemberName = "actual.${symbolProvider.toMemberName(member)}"
                writer.write("XCTAssertEqual(\$L, \$L)", expectedMemberName, actualMemberName)
            }
        }
    }

    private fun renderHeadersInHttpResponse(test: HttpResponseTestCase) {
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
    }

    open class Builder : HttpProtocolUnitTestGenerator.Builder<HttpResponseTestCase>() {
        override fun build(): HttpProtocolUnitTestGenerator<HttpResponseTestCase> {
            return HttpProtocolUnitTestResponseGenerator(this)
        }
    }
}
