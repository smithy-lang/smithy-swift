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

import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.HttpQueryTrait
import software.amazon.smithy.protocoltests.traits.HttpResponseTestCase
import software.amazon.smithy.swift.codegen.RecursiveShapeBoxer
import software.amazon.smithy.swift.codegen.ShapeValueGenerator

/**
 * Generates HTTP protocol unit tests for `httpResponseTest` cases
 */
open class HttpProtocolUnitTestResponseGenerator protected constructor(builder: Builder) :
    HttpProtocolUnitTestGenerator<HttpResponseTestCase>(builder) {

    override val baseTestClassName = "HttpResponseTestBase"

    protected open val outputShape: Shape?
        get() {
            return operation.output.map {
                model.expectShape(it)
            }.orElse(null)
        }

    override fun renderTestBody(test: HttpResponseTestCase) {
        outputShape?.let {
            val symbol = symbolProvider.toSymbol(it)
            writer.openBlock("do {", "} catch let err {") {
                renderBuildHttpResponse(test)
                writer.write("")
                renderActualOutput(test, symbol.name)
                writer.write("")
                renderExpectedOutput(test, it)
                writer.write("")
                renderAssertions(test, it)
                writer.write("")
            }
            writer.indent()
            writer.write("XCTFail(err.localizedDescription)")
            writer.dedent()
            writer.write("}")
        }
    }

    protected fun renderBuildHttpResponse(test: HttpResponseTestCase) {
        writer.openBlock("guard let httpResponse = buildHttpResponse(", ") else {") {
            writer.write("code: ${test.code},")
            renderHeadersInHttpResponse(test)
            test.body.ifPresent { body ->
                if (body.isNotBlank() && body.isNotEmpty()) {
                    // TODO:: handle streaming case?
                    writer.write(
                        "content: ResponseType.data(\"\"\"\n\$L\n\"\"\".data(using: .utf8)),",
                        body
                    )
                }
            }
            writer.write("host: host")
        }
        writer.indent()
        writer.write("XCTFail(\"Something is wrong with the created http response\")")
        writer.write("return")
        writer.dedent()
        writer.write("}")
    }

    /*
    Resolves the Response Decoder to use based on the bodyMediaType trait of HttpResponseTestCase
     */
    protected fun resolveResponseDecoder(test: HttpResponseTestCase): String? {
        var responseDecoder: String? = null
        test.body.ifPresent { body ->
            if (body.isNotBlank() && body.isNotEmpty() && test.bodyMediaType.isPresent) {
                val bodyMediaType = test.bodyMediaType.get()
                responseDecoder = when (bodyMediaType.toLowerCase()) {
                    "application/json" -> "JSONDecoder()"
                    "application/xml" -> "XMLDecoder()"
                    "application/x-www-form-urlencoded" -> TODO("urlencoded form assertion not implemented yet")
                    else -> "JSONDecoder"
                }
            }
        }
        return responseDecoder
    }

    private fun renderActualOutput(test: HttpResponseTestCase, outputStructName: String) {
        val responseDecoder = resolveResponseDecoder(test)
        renderResponseDecoderConfiguration(responseDecoder)
        val decoderParameter = responseDecoder?.let { ", decoder: decoder" } ?: ""
        writer.write("let actual = try \$L(httpResponse: httpResponse\$L)", outputStructName, decoderParameter)
    }

    protected fun renderResponseDecoderConfiguration(responseDecoder: String?) {
        responseDecoder ?: return
        writer.write("let decoder = $responseDecoder")
        writer.write("decoder.dateDecodingStrategy = .secondsSince1970")
    }

    protected fun renderExpectedOutput(test: HttpResponseTestCase, outputShape: Shape) {
        // invoke the DSL builder for the input type
        writer.writeInline("\nlet expected = ")
            .call {
                model = RecursiveShapeBoxer.transform(model)
                ShapeValueGenerator(model, symbolProvider).writeShapeValueInline(writer, outputShape, test.params)
            }
            .write("")
    }

    protected open fun renderAssertions(test: HttpResponseTestCase, outputShape: Shape) {
        val members = outputShape.members().filterNot { it.hasTrait(HttpQueryTrait::class.java) }
        for (member in members) {
            val expectedMemberName = "expected.${symbolProvider.toMemberName(member)}"
            val actualMemberName = "actual.${symbolProvider.toMemberName(member)}"
            if (member.isStructureShape) {
                writer.write("XCTAssert(\$L === \$L)", expectedMemberName, actualMemberName)
            } else {
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
