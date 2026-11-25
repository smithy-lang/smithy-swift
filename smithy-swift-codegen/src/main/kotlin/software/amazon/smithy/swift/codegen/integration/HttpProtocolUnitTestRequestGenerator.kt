/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.protocoltests.traits.HttpRequestTestCase
import software.amazon.smithy.swift.codegen.ShapeValueGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.hasStreamingMember
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.WireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.requestWireProtocol
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer
import software.amazon.smithy.swift.codegen.model.hasEndpointRules
import software.amazon.smithy.swift.codegen.model.toLowerCamelCase
import software.amazon.smithy.swift.codegen.swiftmodules.FoundationTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyStreamsTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTestUtilTypes
import software.amazon.smithy.swift.codegen.utils.isSerdeBenchmarkTest
import java.util.Base64

open class HttpProtocolUnitTestRequestGenerator protected constructor(
    builder: Builder,
) : HttpProtocolUnitTestGenerator<HttpRequestTestCase>(builder) {
    override val testSuiteProtocolSymbol = SmithyTestUtilTypes.HTTPRequestProtocolTestSuite

    override fun renderTestBody(test: HttpRequestTestCase) {
        renderExpectedBlock(test)
        writer.write("")
        renderClientBlock(test)
        renderOperationBlock(test)
    }

    private fun renderExpectedBlock(test: HttpRequestTestCase) {
        if (test.isSerdeBenchmarkTest) return
        val resolvedHostValue = if (test.resolvedHost.isPresent && test.resolvedHost.get() != "") test.resolvedHost.get() else "example.com"
        val hostValue = if (test.host.isPresent && test.host.get() != "") test.host.get() else "example.com"

        // Normalize the URI
        val normalizedUri =
            when {
                test.uri == "/" -> "/"
                test.uri.isEmpty() -> ""
                else -> {
                    val trimmedUri = test.uri.removeSuffix("/")
                    if (!trimmedUri.startsWith('/')) "/$trimmedUri" else trimmedUri
                }
            }

        writer
            .openBlock("let expected = buildExpectedHttpRequest(")
            .write("method: .${test.method.lowercase()},")
            .write("path: \$S,", normalizedUri)
            .call { renderExpectedHeaders(test) }
            .call { renderExpectedQueryParams(test) }
            .call { renderExpectedBody(test) }
            .write("host: \$S,", hostValue)
            .write("resolvedHost: \$S", resolvedHostValue)
            .closeBlock(")")
    }

    private fun renderExpectedBody(test: HttpRequestTestCase) {
        if (test.body.isPresent && test.body.get().isNotBlank()) {
            operation.input.ifPresent {
                val inputShape = model.expectShape(it) as StructureShape
                val data =
                    if (ctx.service.requestWireProtocol == WireProtocol.CBOR) {
                        // Attempt to decode the Base64 data
                        try {
                            val decodedBytes = Base64.getDecoder().decode(test.body.get())
                            // Format decoded bytes into a Swift Data array representation
                            "Data([${decodedBytes.joinToString(", ") { byte -> "0x%02X".format(byte) }}])"
                        } catch (e: IllegalArgumentException) {
                            // Fallback to original string if decoding fails
                            writer.format(
                                "Data(#\"\"\"\n\$L\n\"\"\"#.utf8)",
                                test.body.get(),
                            )
                        }
                    } else {
                        // Default case for non-CBOR protocols
                        writer.format(
                            "Data(#\"\"\"\n\$L\n\"\"\"#.utf8)",
                            test.body.get(),
                        )
                    }

                // Depending on the shape of the input, wrap the expected body in a stream or not
                if (inputShape.hasStreamingMember(model)) {
                    // Wrapping to CachingStream required for test asserts which reads body multiple times
                    writer.write(
                        "body: .stream(\$N(data: \$L, isClosed: true)),",
                        SmithyStreamsTypes.Core.BufferedStream,
                        data,
                    )
                } else {
                    writer.write("body: .data(\$L),", data)
                }
            }
        } else {
            writer.write("body: nil,")
        }
    }

    private fun renderClientBlock(test: HttpRequestTestCase) {
        val args = mutableListOf<String>()
        if (!ctx.service.hasEndpointRules()) {
            test.host.ifPresent { args.add(writer.format("host: \$S", it)) }
        }
        // Create & install benchmark telemetry for serde benchmark tests only
        if (test.isSerdeBenchmarkTest) {
            writer.write("let telemetryProvider = \$N()", SmithyTestUtilTypes.SerdeBenchmarkTelemetryProvider)
            args.add("telemetryProvider: telemetryProvider")
        }
        writer.write("let client = try await makeClient(\$L)", args.joinToString(", "))
    }

    override fun renderSuiteHelpers() {
        ctx.renderMakeClient(writer, ProtocolTestClientKind.REQUEST, telemetryProvider = hasSerdeBenchmarkTests)
    }

    private fun renderOperationBlock(test: HttpRequestTestCase) {
        if (test.isSerdeBenchmarkTest) {
            renderSerdeBenchmarkOperationBlock(test)
            return
        }
        operation.input.ifPresent {
            val inputShape = model.expectShape(it)
            model = RecursiveShapeBoxer.transform(model)
            writer
                .writeInline("\nlet input = ")
                .call {
                    ShapeValueGenerator(model, symbolProvider).writeShapeValueInline(writer, inputShape, test.params)
                }.write("")
            writer.addImport(SwiftDependency.SMITHY.target)
            writer.write(
                "let actual = try await captureRequest { try await client.\$L(input: input) }",
                operation.toLowerCamelCase(),
            )
            renderAssertion(test)
        }
    }

    private fun renderAssertion(test: HttpRequestTestCase) {
        if (test.body.isPresent && test.body.get().isNotBlank()) {
            val contentType =
                when (ctx.service.requestWireProtocol) {
                    WireProtocol.XML -> ".xml"
                    WireProtocol.JSON -> ".json"
                    WireProtocol.FORM_URL -> ".formURL"
                    WireProtocol.CBOR -> ".cbor"
                }
            writer.write("try await assertEqual(expected, actual, bodyContentType: \$L)", contentType)
        } else {
            writer.write("try await assertEqual(expected, actual)")
        }
    }

    private fun renderExpectedQueryParams(test: HttpRequestTestCase) {
        if (test.queryParams.isNotEmpty()) {
            val queryParams = test.queryParams
            writer
                .openBlock("queryParams: [")
                .call {
                    queryParams.forEachIndexed { idx, value ->
                        val suffix = if (idx < queryParams.size - 1) "," else ""
                        writer.write("\$S$suffix", value)
                    }
                }.closeBlock("],")
        }

        if (test.forbidQueryParams.isNotEmpty()) {
            val queryParams = test.forbidQueryParams
            writer
                .openBlock("forbiddenQueryParams: [")
                .call {
                    queryParams.forEachIndexed { idx, value ->
                        val suffix = if (idx < queryParams.size - 1) "," else ""
                        writer.write("\$S$suffix", value)
                    }
                }.closeBlock("],")
        }

        if (test.requireQueryParams.isNotEmpty()) {
            val queryParams = test.requireQueryParams
            writer
                .openBlock("requiredQueryParams: [")
                .call {
                    queryParams.forEachIndexed { idx, value ->
                        val suffix = if (idx < queryParams.size - 1) "," else ""
                        writer.write("\$S$suffix", value)
                    }
                }.closeBlock("],")
        }
    }

    private fun renderExpectedHeaders(test: HttpRequestTestCase) {
        writeHeaders("headers", test.headers)
        writeHeaders("forbiddenHeaders", test.forbidHeaders)
        writeHeaders("requiredHeaders", test.requireHeaders)
    }

    private fun writeHeaders(
        name: String,
        headers: Map<String, String>,
    ) {
        if (headers.isEmpty()) return
        writer.openBlock("\$L: [", "],", name) {
            val contents =
                headers.entries.joinToString(",\n") {
                    writer.format("\$S: \$S", it.key, it.value)
                }
            writer.write(contents)
        }
    }

    private fun writeHeaders(
        name: String,
        headers: List<String>,
    ) {
        if (headers.isEmpty()) return
        writer.openBlock("\$L: [", "],", name) {
            val contents = headers.joinToString(",\n") { writer.format("\$S", it) }
            writer.write(contents)
        }
    }

    class Builder : HttpProtocolUnitTestGenerator.Builder<HttpRequestTestCase>() {
        override fun build(): HttpProtocolUnitTestGenerator<HttpRequestTestCase> = HttpProtocolUnitTestRequestGenerator(this)
    }

    private fun renderSerdeBenchmarkOperationBlock(test: HttpRequestTestCase) {
        operation.input.ifPresent {
            val inputShape = model.expectShape(it)
            model = RecursiveShapeBoxer.transform(model)
            writer
                .writeInline("\nlet input = ")
                .call {
                    ShapeValueGenerator(model, symbolProvider).writeShapeValueInline(writer, inputShape, test.params)
                }.write("")
            writer.write(
                "let path = \$N.default.currentDirectoryPath + \"/../../../../../../../../smithy-swift/instance-results.json\"",
                FoundationTypes.FileManager,
            )
            writer.openBlock(
                "try await \$N().test(id: \$S, type: .request, path: path, telemetryProvider: telemetryProvider) {",
                "}",
                SmithyTestUtilTypes.SerdeBenchmarker,
                test.id,
            ) {
                writer.write("do {")
                writer.indent()
                writer.write("_ = try await client.\$L(input: input)", operation.toLowerCamelCase())
                writer.dedent()
                writer.write("} catch \$N.actual {", SmithyTestUtilTypes.TestCheckError)
                writer.indent()
                writer.write("// no operation")
                writer.dedent()
                writer.write("}")
            }
        }
    }
}
