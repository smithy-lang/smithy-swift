/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.protocol.traits.Rpcv2CborTrait
import software.amazon.smithy.protocoltests.traits.HttpResponseTestCase
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.AWSProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.ResponseClosureUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.WireProtocol
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.model.toUpperCamelCase
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAPITypes
import java.util.Base64

open class HttpProtocolUnitTestErrorGenerator protected constructor(builder: Builder) :
    HttpProtocolUnitTestResponseGenerator(builder) {
    val error: Shape = builder.error ?: throw CodegenException("builder did not set an error shape")
    override val outputShape: Shape? = error

    override fun renderTestBody(test: HttpResponseTestCase) {
        outputShape?.let {
            val operationErrorType = "${operation.toUpperCamelCase()}OutputError"
            writer.openBlock("do {", "} catch {") {
                renderBuildHttpResponse(test)
                writer.write("")
                renderInitOperationError(operationErrorType)
                writer.write("")
                renderCompareActualAndExpectedErrors(test, it, operationErrorType)
                writer.write("")
            }
            writer.indent()
            writer.write("XCTFail(error.localizedDescription)")
            writer.dedent()
            writer.write("}")
        }
    }

    private fun renderInitOperationError(operationErrorType: String) {
        val operationErrorVariableName = operationErrorType.replaceFirstChar { it.lowercase() }
        val responseErrorClosure = ResponseErrorClosureUtils(ctx, writer, operation).render()
        writer.addImport(SwiftDependency.SMITHY_READ_WRITE.target)
        writer.write(
            "let \$L = try await \$L(httpResponse)",
            operationErrorVariableName,
            responseErrorClosure,
        )
    }

    private fun renderCompareActualAndExpectedErrors(
        test: HttpResponseTestCase,
        errorShape: Shape,
        operationErrorType: String
    ) {
        val operationErrorVariableName = operationErrorType.replaceFirstChar { it.lowercase() }
        val errorType = symbolProvider.toSymbol(errorShape).name

        writer.openBlock("if let actual = \$L as? \$L {", "} else {", operationErrorVariableName, errorType) {
            renderExpectedOutput(test, errorShape)
            renderAssertions(test, errorShape)
        }
        writer.indent()
        writer.write("XCTFail(\"The deserialized error type does not match expected type\")")
        writer.dedent()
        writer.write("}")
    }

    override fun renderAssertions(test: HttpResponseTestCase, outputShape: Shape) {
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
            val isCbor = ctx.service.requestWireProtocol == WireProtocol.CBOR ||
                ctx.service.awsProtocol == AWSProtocol.RPCV2_CBOR ||
                ctx.service.responseWireProtocol == WireProtocol.CBOR ||
                test.protocol == Rpcv2CborTrait.ID

            val bodyContent = test.body.get().replace("\\\"", "\\\\\"")
            val data: String = if (isCbor) {
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

        override fun build(): HttpProtocolUnitTestGenerator<HttpResponseTestCase> {
            return HttpProtocolUnitTestErrorGenerator(this)
        }
    }
}
