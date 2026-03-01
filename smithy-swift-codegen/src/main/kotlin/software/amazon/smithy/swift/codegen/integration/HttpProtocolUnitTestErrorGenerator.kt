/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.protocol.traits.Rpcv2CborTrait
import software.amazon.smithy.protocoltests.traits.HttpResponseTestCase
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.AWSProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.WireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.awsProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.requestWireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.responseWireProtocol
import software.amazon.smithy.swift.codegen.model.toLowerCamelCase
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase
import java.util.Base64

open class HttpProtocolUnitTestErrorGenerator protected constructor(
    builder: Builder,
) : HttpProtocolUnitTestResponseGenerator(builder) {
    val error: Shape = builder.error ?: throw CodegenException("builder did not set an error shape")

    override fun renderTestBody(test: HttpResponseTestCase) {
        renderBuildHttpResponse(test)
        writer.write("")
        renderActualOutput()
        writer.write("")
        renderCompareActualAndExpectedErrors(test, error)
    }

    override fun captureResponse() {
        writer.write("var operationError: \$N?", SwiftTypes.Error)
        writer.write("do {")
        writer.indent {
            writer.write("_ = try await client.\$L(input: input)", operation.toLowerCamelCase())
            writer.write("XCTFail(\"Request should have failed\")")
        }
        writer.openBlock("} catch {", "}") {
            writer.write("operationError = error")
        }
    }

    private fun renderCompareActualAndExpectedErrors(
        test: HttpResponseTestCase,
        errorShape: Shape,
    ) {
        val errorType = symbolProvider.toSymbol(errorShape).name

        writer.openBlock("if let actual = operationError as? \$L {", "} else {", errorType) {
            renderExpectedOutput(test, errorShape)
            renderAssertions(test, errorShape)
        }
        writer.indent()
        writer.write("XCTFail(\"The deserialized error type does not match expected type\")")
        writer.dedent()
        writer.write("}")
    }

    override fun renderAssertions(
        test: HttpResponseTestCase,
        outputShape: Shape,
    ) {
        writer.addImport(SwiftDependency.SMITHY_HTTP_API.target)
        writer.write(
            "XCTAssertEqual(actual.httpResponse.statusCode, \$N(rawValue: \$L))",
            SmithyHTTPAPITypes.HTTPStatusCode,
            test.code,
        )
        super.renderAssertions(test, outputShape)
    }

    override fun renderExpectedBody(test: HttpResponseTestCase) {
        if (test.body.isPresent && test.body.get().isNotBlank()) {
            val isCbor =
                ctx.service.requestWireProtocol == WireProtocol.CBOR ||
                    ctx.service.awsProtocol == AWSProtocol.RPCV2_CBOR ||
                    ctx.service.responseWireProtocol == WireProtocol.CBOR ||
                    test.protocol == Rpcv2CborTrait.ID

            val bodyContent = test.body.get().replace("\\\"", "\\\\\"")
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
            writer.write("content: .data(\$L)", data)
        } else {
            writer.write("content: nil")
        }
    }

    class Builder : HttpProtocolUnitTestResponseGenerator.Builder() {
        var error: Shape? = null

        /**
         * Set the error shape to generate the test for
         */
        fun error(shape: Shape) = apply { error = shape }

        override fun build(): HttpProtocolUnitTestGenerator<HttpResponseTestCase> = HttpProtocolUnitTestErrorGenerator(this)
    }
}
