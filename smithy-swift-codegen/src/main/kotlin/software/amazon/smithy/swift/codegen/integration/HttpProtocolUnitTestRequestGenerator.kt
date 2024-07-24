/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

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
        val resolvedHostValue = if (test.resolvedHost.isPresent && test.resolvedHost.get() != "") test.resolvedHost.get() else "example.com"
        val hostValue = if (test.host.isPresent && test.host.get() != "") test.host.get() else "example.com"

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
            val url = "http://${host ?: "example.com"}"
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
        operation.input.ifPresent {
            val inputShape = model.expectShape(it)
            model = RecursiveShapeBoxer.transform(model)
            writer.writeInline("\nlet input = ")
                .call {
                    ShapeValueGenerator(model, symbolProvider).writeShapeValueInline(writer, inputShape, test.params)
                }
                .write("")
            writer.addImport(SwiftDependency.SMITHY.target)
            writer.write(
                """
                do {
                    _ = try await client.${operation.toLowerCamelCase()}(input: input)
                } catch TestCheckError.actual(let actual) {
                    ${'$'}{C|}
                }
                """.trimIndent(),
                Runnable { renderBodyAssert(test) },
            )
        }
    }

    private fun renderBodyAssert(test: HttpRequestTestCase) {
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
        writeHeaders("headers", test.headers)
        writeHeaders("forbiddenHeaders", test.forbidHeaders)
        writeHeaders("requiredHeaders", test.requireHeaders)
    }

    private fun writeHeaders(name: String, headers: Map<String, String>) {
        if (headers.isEmpty()) return
        writer.openBlock("\$L: [", "],", name) {
            val contents = headers.entries.joinToString(",\n") {
                writer.format("\$S: \$S", it.key, it.value)
            }
            writer.write(contents)
        }
    }

    private fun writeHeaders(name: String, headers: List<String>) {
        if (headers.isEmpty()) return
        writer.openBlock("\$L: [", "],", name) {
            val contents = headers.joinToString(",\n") { writer.format("\$S", it) }
            writer.write(contents)
        }
    }

    class Builder : HttpProtocolUnitTestGenerator.Builder<HttpRequestTestCase>() {
        override fun build(): HttpProtocolUnitTestGenerator<HttpRequestTestCase> {
            return HttpProtocolUnitTestRequestGenerator(this)
        }
    }
}
