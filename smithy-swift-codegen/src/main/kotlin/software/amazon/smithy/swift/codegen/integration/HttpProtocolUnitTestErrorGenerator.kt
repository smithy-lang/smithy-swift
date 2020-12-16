/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.protocoltests.traits.HttpResponseTestCase
import software.amazon.smithy.swift.codegen.defaultName

open class HttpProtocolUnitTestErrorGenerator protected constructor(builder: Builder) :
    HttpProtocolUnitTestResponseGenerator(builder) {
    val error: Shape = builder.error ?: throw CodegenException("builder did not set an error shape")
    override val outputShape: Shape? = error

    override fun renderTestBody(test: HttpResponseTestCase) {
        outputShape?.let {
            val operationErrorType = "${operation.defaultName()}Error"
            writer.openBlock("do {", "} catch let err {") {
                renderBuildHttpResponse(test)
                writer.write("")
                renderInitOperationError(test, operationErrorType)
                writer.write("")
                renderCompareActualAndExpectedErrors(test, it, operationErrorType)
                writer.write("")
            }
            writer.indent()
            writer.write("XCTFail(err.localizedDescription)")
            writer.dedent()
            writer.write("}")
        }
    }

    private fun renderInitOperationError(test: HttpResponseTestCase, operationErrorType: String) {
        val operationErrorVariableName = operationErrorType.decapitalize()
        val responseDecoder = resolveResponseDecoder(test)
        renderResponseDecoderConfiguration(responseDecoder)
        val decoderParameter = responseDecoder?.let { ", decoder: decoder" } ?: ""

        writer.write("let \$L = try \$L(httpResponse: httpResponse\$L)",
            operationErrorVariableName,
            operationErrorType,
            decoderParameter
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

        writer.openBlock("if case .\$L(let actual) = \$L {", "} else {", errorVariableName, operationErrorVariableName) {
            renderExpectedOutput(test, errorShape)
            renderAssertions(test, errorShape)
        }
        writer.indent()
        writer.write("XCTFail(\"The deserialized error type does not match expected type\")")
        writer.dedent()
        writer.write("}")
    }

    override fun renderAssertions(test: HttpResponseTestCase, outputShape: Shape) {
        writer.write("XCTAssertEqual(actual._statusCode, HttpStatusCode(rawValue: \$L))", test.code)
        super.renderAssertions(test, outputShape)
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
