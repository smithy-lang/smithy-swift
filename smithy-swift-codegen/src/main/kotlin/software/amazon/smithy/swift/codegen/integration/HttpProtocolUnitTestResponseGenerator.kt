/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.DefaultTrait
import software.amazon.smithy.model.traits.HttpHeaderTrait
import software.amazon.smithy.model.traits.HttpPayloadTrait
import software.amazon.smithy.model.traits.HttpPrefixHeadersTrait
import software.amazon.smithy.protocoltests.traits.HttpResponseTestCase
import software.amazon.smithy.swift.codegen.ShapeValueGenerator
import software.amazon.smithy.swift.codegen.hasStreamingMember
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.ResponseClosureUtils
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyStreamsTypes

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
            renderActualOutput(symbol)
            writer.write("")
            renderExpectedOutput(test, it)
            writer.write("")
            renderAssertions(test, it)
            writer.write("")
        }
    }

    protected fun renderBuildHttpResponse(test: HttpResponseTestCase) {
        writer.openBlock("guard let httpResponse = buildHttpResponse(", ") else {") {
            renderBuildHttpResponseParams(test)
        }
        writer.indent()
        writer.write("XCTFail(\"Something is wrong with the created http response\")")
        writer.write("return")
        writer.dedent()
        writer.write("}")
    }

    open fun renderExpectedBody(test: HttpResponseTestCase) {
        if (test.body.isPresent) {
            operation.output.ifPresent {
                if (test.body.get().isNotBlank()) {
                    val outputShape = model.expectShape(it) as StructureShape
                    val data = writer.format(
                        "Data(\"\"\"\n\$L\n\"\"\".utf8)",
                        test.body.get().replace("\\\"", "\\\\\"")
                    )
                    // depending on the shape of the output, we may need to wrap the body in a stream
                    if (outputShape.hasStreamingMember(model)) {
                        // wrapping to CachingStream required for test asserts which reads body multiple times
                        writer.write(
                            "content: .stream(\$N(data: \$L, isClosed: true))",
                            SmithyStreamsTypes.Core.BufferedStream,
                            data
                        )
                    } else {
                        writer.write("content: .data(\$L)", data)
                    }
                } else if (test.body.get().isBlank() && bodyHasDefaultValue()) {
                    // Expected body is blank but not because it's nil, but because it's a default empty blob value
                    writer.write("content: .data(Data(\"\".utf8))")
                } else {
                    // Expected body is blank and underlying member shape does not have default values.
                    writer.write("content: nil")
                }
            }
        } else {
            writer.write("content: nil")
        }
    }

    private fun bodyHasDefaultValue(): Boolean {
        var result = false
        operation.output.ifPresent {
            val outputShape = model.expectShape(it) as StructureShape
            outputShape.allMembers.forEach {
                val member = it.value
                val target = model.expectShape(member.target)
                val defaultValueExists = member.hasTrait<DefaultTrait>() || target.hasTrait<DefaultTrait>()
                // If a top level input member shape has the payload trait, it's a bound payload member
                val isBoundPayloadMember = member.hasTrait<HttpPayloadTrait>()
                // If a top level input member doesn't have payload trait, header trait nor prefix header trait,
                //  it is an unbound payload member.
                val isUnboundPayloadMember = !member.hasTrait<HttpHeaderTrait>() &&
                    !member.hasTrait<HttpPrefixHeadersTrait>() &&
                    !member.hasTrait<HttpPayloadTrait>()
                // If a member has default value and goes in payload, return true
                if (defaultValueExists && (isBoundPayloadMember || isUnboundPayloadMember)) {
                    result = true
                    return@ifPresent
                }
            }
        }
        return result
    }

    private fun renderBuildHttpResponseParams(test: HttpResponseTestCase) {
        writer.write("code: \$L,", test.code)
        renderExpectedHeaders(test)
        renderExpectedBody(test)
    }

    private fun renderExpectedHeaders(test: HttpResponseTestCase) {
        if (test.headers.isNotEmpty()) {
            writer.openBlock("headers: [")
                .call {
                    for ((idx, hdr) in test.headers.entries.withIndex()) {
                        val suffix = if (idx < test.headers.size - 1) "," else ""
                        writer.write("\$S: \$S$suffix", hdr.key, hdr.value)
                    }
                }
                .closeBlock("],")
        } else {
            writer.write("headers: nil,")
        }
    }

    private fun renderActualOutput(outputStruct: Symbol) {
        val responseClosure = ResponseClosureUtils(ctx, writer, operation).render()
        writer.write("let actual: \$N = try await \$L(httpResponse)", outputStruct, responseClosure)
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
        writer.write("XCTAssertEqual(actual, expected)")
    }

    open class Builder : HttpProtocolUnitTestGenerator.Builder<HttpResponseTestCase>() {
        override fun build(): HttpProtocolUnitTestGenerator<HttpResponseTestCase> {
            return HttpProtocolUnitTestResponseGenerator(this)
        }
    }
}
