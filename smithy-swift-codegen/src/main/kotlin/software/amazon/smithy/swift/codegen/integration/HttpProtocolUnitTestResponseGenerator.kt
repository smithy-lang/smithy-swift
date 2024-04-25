/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.DoubleShape
import software.amazon.smithy.model.shapes.FloatShape
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.ErrorTrait
import software.amazon.smithy.model.traits.HttpQueryTrait
import software.amazon.smithy.protocoltests.traits.HttpResponseTestCase
import software.amazon.smithy.swift.codegen.ShapeValueGenerator
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.customtraits.EquatableConformanceTrait
import software.amazon.smithy.swift.codegen.hasStreamingMember
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.ResponseClosureUtils
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer
import software.amazon.smithy.swift.codegen.model.hasTrait

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
            renderActualOutput(test, symbol)
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
        if (test.body.isPresent && test.body.get().isNotBlank()) {
            operation.output.ifPresent {
                val outputShape = model.expectShape(it) as StructureShape
                val data = writer.format("Data(\"\"\"\n\$L\n\"\"\".utf8)", test.body.get().replace("\\\"", "\\\\\""))
                // depending on the shape of the output, we may need to wrap the body in a stream
                if (outputShape.hasStreamingMember(model)) {
                    // wrapping to CachingStream required for test asserts which reads body multiple times
                    writer.write("content: .stream(BufferedStream(data: \$L, isClosed: true))", data)
                } else {
                    writer.write("content: .data(\$L)", data)
                }
            }
        } else {
            writer.write("content: nil")
        }
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

    protected fun needsResponseDecoder(test: HttpResponseTestCase): Boolean {
        var needsDecoder = true
        test.body.ifPresent { body ->
            if (body.isNotBlank() && body.isNotEmpty()) {
                needsDecoder = true
            }
        }
        return needsDecoder
    }

    private fun renderActualOutput(test: HttpResponseTestCase, outputStruct: Symbol) {
        val needsResponseDecoder = needsResponseDecoder(test)
        if (needsResponseDecoder) {
            renderResponseDecoder()
        }
        val responseClosure = ResponseClosureUtils(ctx, writer, operation).render()
        writer.write("let actual: \$N = try await \$L(httpResponse)", outputStruct, responseClosure)
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
        findShapesRequiringEquatable(outputShape)
        writer.write("XCTAssertEqual(actual, expected)")
    }

    private fun findShapesRequiringEquatable(shape: Shape) {
        if (hasBeenRenderedEquatable.contains(identifier(ctx, shape)) ||
            shape.hasTrait<EquatableConformanceTrait>()
        ) { return }
        hasBeenRenderedEquatable.add(identifier(ctx, shape))
        when (shape) {
            is StructureShape -> {
                renderEquatable(shape)
                val memberShapes = shape.members().map { ctx.model.expectShape(it.target) }
                memberShapes.forEach { findShapesRequiringEquatable(it) }
            }
            is UnionShape -> {
                renderEquatable(shape)
                val memberShapes = shape.members().map { ctx.model.expectShape(it.target) }
                memberShapes.forEach { findShapesRequiringEquatable(it) }
            }
            is MapShape -> {
                findShapesRequiringEquatable(ctx.model.expectShape(shape.value.target))
            }
            is ListShape -> {
                findShapesRequiringEquatable(ctx.model.expectShape(shape.member.target))
            }
        }
    }

    private fun identifier(ctx: ProtocolGenerator.GenerationContext, shape: Shape): String {
        return "${ctx.service.id}.${shape.id}"
    }

    private fun renderEquatable(shape: Shape) {
        if (!(shape is StructureShape || shape is UnionShape)) { return }
        val symbol = ctx.symbolProvider.toSymbol(shape)
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./${ctx.settings.moduleName}Tests/models/${symbol.name}+Equatable.swift")
            .name(symbol.name)
            .build()
        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(ctx.settings.moduleName)
            writer.openBlock("extension \$L: \$N {", "}", symbol.fullName, SwiftTypes.Protocols.Equatable) {
                writer.write("")
                writer.openBlock("public static func ==(lhs: \$L, rhs: \$L) -> Bool {", "}", symbol.fullName, symbol.fullName) {
                    when (shape) {
                        is StructureShape -> {
                            shape.members().filter { !it.hasTrait<HttpQueryTrait>() }.forEach { member ->
                                val propertyName = ctx.symbolProvider.toMemberName(member)
                                val path = "properties.".takeIf { shape.hasTrait<ErrorTrait>() } ?: ""
                                val propertyAccessor = "$path$propertyName"
                                val target = ctx.model.expectShape(member.target)
                                when (target) {
                                    is FloatShape, is DoubleShape -> {
                                        writer.write(
                                            "if (lhs.\$L?.isNaN ?? false && rhs.\$L?.isNaN ?? false) || (lhs.\$L != rhs.\$L) { return false }",
                                            propertyAccessor,
                                            propertyAccessor,
                                            propertyAccessor,
                                            propertyAccessor,
                                        )
                                    }
                                    else -> {
                                        writer.write("if lhs.\$L != rhs.\$L { return false }", propertyAccessor, propertyAccessor)
                                    }
                                }
                            }
                            writer.write("return true")
                        }
                        is UnionShape -> {
                            writer.openBlock("switch (lhs, rhs) {", "}") {
                                shape.members().forEach { member ->
                                    val enumCaseName = ctx.symbolProvider.toMemberName(member)
                                    writer.write("case (.\$L(let lhs), .\$L(let rhs)):", enumCaseName, enumCaseName)
                                    writer.indent {
                                        writer.write("return lhs == rhs")
                                    }
                                }
                                writer.write("default: return false")
                            }
                        }
                    }
                }
            }
        }
    }

    open class Builder : HttpProtocolUnitTestGenerator.Builder<HttpResponseTestCase>() {
        override fun build(): HttpProtocolUnitTestGenerator<HttpResponseTestCase> {
            return HttpProtocolUnitTestResponseGenerator(this)
        }
    }
}

val hasBeenRenderedEquatable = mutableSetOf<String>()
