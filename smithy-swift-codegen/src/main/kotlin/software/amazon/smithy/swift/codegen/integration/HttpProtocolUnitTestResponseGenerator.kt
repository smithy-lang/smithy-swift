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
import software.amazon.smithy.protocol.traits.Rpcv2CborTrait
import software.amazon.smithy.protocoltests.traits.HttpResponseTestCase
import software.amazon.smithy.swift.codegen.ShapeValueGenerator
import software.amazon.smithy.swift.codegen.hasStreamingMember
import software.amazon.smithy.swift.codegen.integration.serde.SerdeUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.AWSProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.ResponseClosureUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.WireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.awsProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.requestWireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.responseWireProtocol
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.swiftmodules.FoundationTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyCBORTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyStreamsTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes
import java.util.Base64

/**
 * Generates HTTP protocol unit tests for `httpResponseTest` cases
 */
open class HttpProtocolUnitTestResponseGenerator protected constructor(
    builder: Builder,
) : HttpProtocolUnitTestGenerator<HttpResponseTestCase>(builder) {
    override val baseTestClassName = "HttpResponseTestBase"

    protected open val outputShape: Shape?
        get() {
            return operation.output
                .map {
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
        if (!test.body.isPresent) {
            writer.write("content: nil")
            return
        }

        val bodyContent = test.body.get()
        val isCbor =
            ctx.service.requestWireProtocol == WireProtocol.CBOR ||
                ctx.service.awsProtocol == AWSProtocol.RPCV2_CBOR ||
                ctx.service.responseWireProtocol == WireProtocol.CBOR ||
                test.protocol == Rpcv2CborTrait.ID

        val data: String =
            if (isCbor) {
                // Attempt to decode Base64 data once for CBOR
                try {
                    val decodedBytes = Base64.getDecoder().decode(bodyContent)
                    "Data([${decodedBytes.joinToString(", ") { byte -> "0x%02X".format(byte) }}])"
                } catch (e: IllegalArgumentException) {
                    // Fallback to Swift Data representation for invalid Base64
                    "Data(\"\"\"\n$bodyContent\n\"\"\".utf8)"
                }
            } else {
                // Non-CBOR protocols default
                "Data(\"\"\"\n$bodyContent\n\"\"\".utf8)"
            }

        operation.output.ifPresent {
            val outputShape = model.expectShape(it) as StructureShape

            if (bodyContent.isNotBlank()) {
                if (outputShape.hasStreamingMember(model)) {
                    writer.write(
                        "content: .stream(\$N(data: \$L, isClosed: true))",
                        SmithyStreamsTypes.Core.BufferedStream,
                        data,
                    )
                } else {
                    writer.write("content: .data($data)")
                }
            } else if (bodyContent.isBlank() && bodyHasDefaultValue()) {
                writer.write("content: .data($data)")
            } else {
                writer.write("content: nil")
            }
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
                val isUnboundPayloadMember =
                    !member.hasTrait<HttpHeaderTrait>() &&
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
            writer
                .openBlock("headers: [")
                .call {
                    for ((idx, hdr) in test.headers.entries.withIndex()) {
                        val suffix = if (idx < test.headers.size - 1) "," else ""
                        writer.write("\$S: \$S$suffix", hdr.key, hdr.value)
                    }
                }.closeBlock("],")
        } else {
            writer.write("headers: nil,")
        }
    }

    private fun renderActualOutput(outputStruct: Symbol) {
        if (SerdeUtils.useSchemaBased(ctx)) {
            writer.write("let codec = \$N()", SmithyCBORTypes.Codec)
            writer.write("let httpResponseData = try await httpResponse.body.readData() ?? \$N()", FoundationTypes.Data)
            writer.write("let deserializer = try codec.makeDeserializer(data: httpResponseData)")
            writer.write("let actual = try \$N.deserialize(deserializer)", outputStruct)
        } else {
            val responseClosure = ResponseClosureUtils(ctx, writer, operation).render()
            writer.write("let actual: \$N = try await \$L(httpResponse)", outputStruct, responseClosure)
        }
    }

    protected fun renderExpectedOutput(
        test: HttpResponseTestCase,
        outputShape: Shape,
    ) {
        // invoke the DSL builder for the input type
        writer
            .writeInline("\nlet expected = ")
            .call {
                model = RecursiveShapeBoxer.transform(model)
                ShapeValueGenerator(model, symbolProvider).writeShapeValueInline(writer, outputShape, test.params)
            }.write("")
    }

    protected open fun renderAssertions(
        test: HttpResponseTestCase,
        outputShape: Shape,
    ) {
        writer.write("XCTAssertEqual(actual, expected)")
    }

    open class Builder : HttpProtocolUnitTestGenerator.Builder<HttpResponseTestCase>() {
        override fun build(): HttpProtocolUnitTestGenerator<HttpResponseTestCase> = HttpProtocolUnitTestResponseGenerator(this)
    }
}
