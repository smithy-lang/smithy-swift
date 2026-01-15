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
import software.amazon.smithy.swift.codegen.integration.serde.SerdeUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.AWSProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.ResponseErrorClosureUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.WireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.awsProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.requestWireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.responseWireProtocol
import software.amazon.smithy.swift.codegen.model.toUpperCamelCase
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase
import java.util.Base64

open class HttpProtocolUnitTestErrorGenerator protected constructor(
    builder: Builder,
) : HttpProtocolUnitTestResponseGenerator(builder) {
    val error: Shape = builder.error ?: throw CodegenException("builder did not set an error shape")
    override val outputShape: Shape? = error

    override fun renderTestBody(test: HttpResponseTestCase) {
        outputShape?.let {
            val operationErrorType = "${operation.toUpperCamelCase()}OutputError"
            renderBuildHttpResponse(test)
            writer.write("")
            renderInitOperationError(operationErrorType)
            writer.write("")
            renderCompareActualAndExpectedErrors(test, it)
        }
    }

    private fun renderInitOperationError(operationErrorType: String) {
        if (SerdeUtils.useSchemaBased(ctx)) {
            writer.write("var operationError: \$N?", SwiftTypes.Error)
            writer.write(
                "let clientProtocol = \$N().clientProtocol",
                httpProtocolCustomizable.configuratorSymbol,
            )
            writer.write("do {")
            writer.indent {
                writer.write(
                    "let operation = \$LClient.\$LOperation",
                    ctx.settings.clientBaseName,
                    operation.id.name.toLowerCamelCase(),
                )
                writer.openBlock(
                    "_ = try await clientProtocol.deserializeResponse(",
                    ")",
                ) {
                    writer.write("operation: operation,")
                    writer.write("context: \$N().build(),", SmithyTypes.ContextBuilder)
                    writer.write("response: httpResponse")
                }
                writer.write("XCTFail(\"Operation should have thrown an error\")")
            }
            writer.write("} catch {")
            writer.indent {
                writer.write("operationError = error")
            }
            writer.write("}")
            return
        }
        val responseErrorClosure = ResponseErrorClosureUtils(ctx, writer, operation).render()
        writer.addImport(SwiftDependency.SMITHY_READ_WRITE.target)
        writer.write(
            "let operationError = try await \$L(httpResponse)",
            responseErrorClosure,
        )
    }

    private fun renderCompareActualAndExpectedErrors(
        test: HttpResponseTestCase,
        errorShape: Shape,
    ) {
        val errorSymbol = symbolProvider.toSymbol(errorShape)

        writer.openBlock(
            "if let actual = operationError as? \$N {",
            "} else {",
            errorSymbol,
        ) {
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
