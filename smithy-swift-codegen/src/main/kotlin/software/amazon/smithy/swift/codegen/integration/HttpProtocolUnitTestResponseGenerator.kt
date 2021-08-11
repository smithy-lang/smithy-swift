/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.HttpQueryTrait
import software.amazon.smithy.protocoltests.traits.HttpMessageTestCase
import software.amazon.smithy.protocoltests.traits.HttpResponseTestCase
import software.amazon.smithy.swift.codegen.ShapeValueGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.getOrNull
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer
import software.amazon.smithy.swift.codegen.model.isBoxed

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
            renderBuildHttpResponse(test)
            writer.write("")
            renderActualOutput(test, symbol.name)
            writer.write("")
            renderExpectedOutput(test, it)
            writer.write("")
            renderAssertions(test, it)
            writer.write("")
        }
    }

    protected fun renderBuildHttpResponse(test: HttpResponseTestCase) {
        writer.openBlock("guard let httpResponse = buildHttpResponse(", ") else {") {
            writer.write("code: ${test.code},")
            renderHeadersInHttpResponse(test)
            test.body.ifPresent { body ->
                if (body.isNotBlank() && body.isNotEmpty()) {
                    writer.write(
                        "content: HttpBody.stream(ByteStream.from(data: \"\"\"\n\$L\n\"\"\".data(using: .utf8)!)),",
                        body.replace(".000", "")
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

    protected fun needsResponseDecoder(test: HttpResponseTestCase): Boolean {
        var needsDecoder = false
        test.body.ifPresent { body ->
            if (body.isNotBlank() && body.isNotEmpty() && test.bodyMediaType.isPresent) {
                needsDecoder = true
            }
        }
        return needsDecoder
    }

    private fun renderActualOutput(test: HttpResponseTestCase, outputStructName: String) {
        val needsResponseDecoder = needsResponseDecoder(test)
        if (needsResponseDecoder) {
            renderResponseDecoder()
        }
        val decoderParameter = if (needsResponseDecoder) ", decoder: decoder" else ""
        writer.write("let actual = try \$L(httpResponse: httpResponse\$L)", outputStructName, decoderParameter)
    }

    protected fun renderResponseDecoder() {
        val decoderProperty = httpProtocolCustomizable.getClientProperties().filterIsInstance<HttpResponseDecoder>().firstOrNull()
        decoderProperty?.renderInstantiation(writer)
        decoderProperty?.renderConfiguration(writer)
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
        renderMemberAssertions(writer, test, members, model, symbolProvider, "expected", "actual")
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

fun renderMemberAssertions(writer: SwiftWriter, test: HttpMessageTestCase, members: Collection<MemberShape>, model: Model, symbolProvider: SymbolProvider, expected: String, actual: String) {
    for (member in members) {
        val shape = model.expectShape(member.target.toShapeId())
        val expectedMemberName = "$expected.${symbolProvider.toMemberName(member)}"
        val actualMemberName = "$actual.${symbolProvider.toMemberName(member)}"
        if (member.isStructureShape) {
            writer.write("XCTAssert(\$L === \$L)", expectedMemberName, actualMemberName)
        } else if ((shape.isDoubleShape || shape.isFloatShape)) {
            val stringNodes = test.params.stringMap.values.map { it.asStringNode().getOrNull() }
            if (stringNodes.isNotEmpty() && stringNodes.mapNotNull { it?.value }.contains("NaN")) {
                val suffix = if (symbolProvider.toSymbol(shape).isBoxed()) "?" else ""
                writer.write("XCTAssertEqual(\$L$suffix.isNaN, \$L$suffix.isNaN)", expectedMemberName, actualMemberName)
            } else {
                writer.write("XCTAssertEqual(\$L, \$L)", expectedMemberName, actualMemberName)
            }
        } else {
            writer.write("XCTAssertEqual(\$L, \$L)", expectedMemberName, actualMemberName)
        }
    }
}
