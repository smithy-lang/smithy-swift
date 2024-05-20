/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.protocoltests.traits.HttpResponseTestCase
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.ResponseErrorClosureUtils
import software.amazon.smithy.swift.codegen.model.toUpperCamelCase

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
                renderInitOperationError(test, operationErrorType)
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

    private fun renderInitOperationError(test: HttpResponseTestCase, operationErrorType: String) {
        val operationErrorVariableName = operationErrorType.decapitalize()
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
        val operationErrorVariableName = operationErrorType.decapitalize()
        val errorType = symbolProvider.toSymbol(errorShape).name
        val errorVariableName = errorType.decapitalize()

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
        writer.write("XCTAssertEqual(actual.httpResponse.statusCode, HttpStatusCode(rawValue: \$L))", test.code)
        super.renderAssertions(test, outputShape)
    }

    override fun renderExpectedBody(test: HttpResponseTestCase) {
        if (test.body.isPresent && test.body.get().isNotBlank()) {
            val data = writer.format("Data(\"\"\"\n\$L\n\"\"\".utf8)", test.body.get().replace("\\\"", "\\\\\""))
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
