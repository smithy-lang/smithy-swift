/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.protocoltests.traits.HttpRequestTestCase
import software.amazon.smithy.rulesengine.traits.EndpointRuleSetTrait
import software.amazon.smithy.swift.codegen.ShapeValueGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.hasStreamingMember
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.WireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.requestWireProtocol
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer
import software.amazon.smithy.swift.codegen.model.toLowerCamelCase
import software.amazon.smithy.swift.codegen.model.toUpperCamelCase
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyStreamsTypes

open class HttpProtocolUnitTestRequestGenerator protected constructor(builder: Builder) :
    HttpProtocolUnitTestGenerator<HttpRequestTestCase>(builder) {
    override val baseTestClassName = "HttpRequestTestBase"

    override fun renderTestBody(test: HttpRequestTestCase) {
        renderExpectedBlock(test)
        writer.write("")
        renderClientBlock(test)
        renderOperationBlock(test)
    }

    private fun renderExpectedBlock(test: HttpRequestTestCase) {
        var resolvedHostValue = if (test.resolvedHost.isPresent && test.resolvedHost.get() != "") test.resolvedHost.get() else "example.com"
        var hostValue = if (test.host.isPresent && test.host.get() != "") test.host.get() else "example.com"

        // Normalize the URI
        val normalizedUri = when {
            test.uri == "/" -> "/"
            test.uri.isEmpty() -> ""
            else -> {
                val trimmedUri = test.uri.removeSuffix("/")
                if (!trimmedUri.startsWith('/')) "/$trimmedUri" else trimmedUri
            }
        }

        writer.openBlock("let expected = buildExpectedHttpRequest(")
            .write("method: .${test.method.toLowerCase()},")
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
                val data = writer.format(
                    "Data(\"\"\"\n\$L\n\"\"\".utf8)",
                    test.body.get().replace("\\\"", "\\\\\""),
                )
                // depending on the shape of the input, wrap the expected body in a stream or not
                if (inputShape.hasStreamingMember(model)) {
                    // wrapping to CachingStream required for test asserts which reads body multiple times
                    writer.write("body: .stream(\$N(data: \$L, isClosed: true)),", SmithyStreamsTypes.Core.BufferedStream, data)
                } else {
                    writer.write("body: .data(\$L),", data)
                }
            }
        } else {
            writer.write("body: nil,")
        }
    }

    private fun renderClientBlock(test: HttpRequestTestCase) {
        val serviceShape = ctx.service
        val clientName = "${ctx.settings.sdkId}Client"

        if (!serviceShape.getTrait(EndpointRuleSetTrait::class.java).isPresent) {
            val host: String? = test.host.orElse(null)
            val url: String = "http://${host ?: "example.com"}"
            writer.write("\nlet config = try await $clientName.${clientName}Configuration(endpointResolver: StaticEndpointResolver(endpoint: try \$N(urlString: \$S)))", SmithyHTTPAPITypes.Endpoint, url)
        } else {
            writer.write("\nlet config = try await $clientName.${clientName}Configuration()")
        }
        writer.write("config.region = \"us-west-2\"")
        writer.write("config.httpClientEngine = ProtocolTestClient()")
        writer.write("config.idempotencyTokenGenerator = ProtocolTestIdempotencyTokenGenerator()")
        writer.write("let client = $clientName(config: config)")
    }

    private fun renderOperationBlock(test: HttpRequestTestCase) {
        operation.input.ifPresent { it ->
            val clientName = "${ctx.settings.sdkId}Client"
            val inputShape = model.expectShape(it)
            model = RecursiveShapeBoxer.transform(model)
            writer.writeInline("\nlet input = ")
                .call {
                    ShapeValueGenerator(model, symbolProvider).writeShapeValueInline(writer, inputShape, test.params)
                }
                .write("")
            val inputSymbol = symbolProvider.toSymbol(inputShape)
            writer.addImport(SwiftDependency.SMITHY.target)
            writer.write(
                """
                do {
                    _ = try await client.${operation.toLowerCamelCase()}(input: input)
                } catch TestCheckError.actual(let actual) {
                    ${'$'}{C|}
                }
                """.trimIndent(),
                Runnable { renderBodyAssert(test, inputSymbol, inputShape) },
            )
        }
    }

    private fun resolveHttpMethod(op: OperationShape): String {
        val httpTrait = httpBindingResolver.httpTrait(op)
        return httpTrait.method.toLowerCase()
    }

    private fun renderBodyAssert(test: HttpRequestTestCase, inputSymbol: Symbol, inputShape: Shape) {
        if (test.body.isPresent && test.body.get().isNotBlank()) {
            writer.openBlock(
                "try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in",
                "})",
            ) {
                writer.write("XCTAssertNotNil(actualHttpBody, \"The actual ByteStream is nil\")")
                writer.write("XCTAssertNotNil(expectedHttpBody, \"The expected ByteStream is nil\")")
                val contentType = when (ctx.service.requestWireProtocol) {
                    WireProtocol.XML -> ".xml"
                    WireProtocol.JSON -> ".json"
                    WireProtocol.FORM_URL -> ".formURL"
                }
                writer.write("try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, contentType: \$L)", contentType)
            }
        } else {
            writer.write(
                "try await self.assertEqual(expected, actual)",
            )
        }
    }

    private fun renderExpectedQueryParams(test: HttpRequestTestCase) {
        if (test.queryParams.isNotEmpty()) {
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

        if (test.forbidQueryParams.isNotEmpty()) {
            val queryParams = test.forbidQueryParams
            writer.openBlock("forbiddenQueryParams: [")
                .call {
                    queryParams.forEachIndexed { idx, value ->
                        val suffix = if (idx < queryParams.size - 1) "," else ""
                        writer.write("\$S$suffix", value)
                    }
                }
                .closeBlock("],")
        }

        if (test.requireQueryParams.isNotEmpty()) {
            val queryParams = test.requireQueryParams
            writer.openBlock("requiredQueryParams: [")
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

        if (test.forbidHeaders.isNotEmpty()) {
            val forbiddenHeaders = test.forbidHeaders
            writer.openBlock("forbiddenHeaders: [")
                .call {
                    forbiddenHeaders.forEachIndexed { idx, value ->
                        val suffix = if (idx < forbiddenHeaders.size - 1) "," else ""
                        writer.write("\$S$suffix", value)
                    }
                }
                .closeBlock("],")
        }

        if (test.requireHeaders.isNotEmpty()) {
            val requiredHeaders = test.requireHeaders
            writer.openBlock("requiredHeaders: [")
                .call {
                    requiredHeaders.forEachIndexed { idx, value ->
                        val suffix = if (idx < requiredHeaders.size - 1) "," else ""
                        writer.write("\$S$suffix", value)
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
