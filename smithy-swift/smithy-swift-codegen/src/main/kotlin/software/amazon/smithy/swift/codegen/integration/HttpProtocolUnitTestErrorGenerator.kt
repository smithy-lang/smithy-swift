/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.defaultName
import software.amazon.smithy.swift.codegen.hasStreamingMember
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.protocoltests.traits.HttpResponseTestCase

open class HttpProtocolUnitTestErrorGenerator protected constructor(builder: Builder) :
    HttpProtocolUnitTestResponseGenerator(builder) {
    val error: Shape = builder.error ?: throw CodegenException("builder did not set an error shape")
    override val outputShape: Shape? = error

    override fun renderTestBody(test: HttpResponseTestCase) {
        outputShape?.let {
            val operationErrorType = operation.defaultName()
            writer.openBlock("do {", "} catch let err {") {
                renderBuildHttpResponse(test)
                renderInitOperationError(test, operationErrorType)
                writer.write("")
                renderCompareActualAndExpectedErrors(test, it, operationErrorType)
                renderAssertions(test, it)
            }.write("XCTFail(err.localizedDescription)").closeBlock("}")
        }
    }

    private fun renderInitOperationError(test: HttpResponseTestCase, operationErrorType: String) {
        val operationErrorVariableName = operationErrorType.decapitalize()
        val responseDecoder = resolveResponseDecoder(test)
        renderResponseDecoderConfiguration(responseDecoder)
        val decoderParameter = responseDecoder?.let { "" } ?: ", decoder: decoder"

        writer.openBlock("guard let \$L = try? \$L(httpResponse: httpResponse\$L) else {",
            "}",
            operationErrorVariableName,
            operationErrorType,
            decoderParameter
        ) {
            writer.write("XCTFail(\"Failed to deserialize the error shape\")")
            writer.write("return")
        }
    }

    private fun renderCompareActualAndExpectedErrors(
        test: HttpResponseTestCase,
        errorShape: Shape,
        operationErrorType: String) {
        val operationErrorVariableName = operationErrorType.decapitalize()
        val errorType = symbolProvider.toSymbol(errorShape).name
        val errorVariableName = errorType.decapitalize()

        writer.openBlock("if case .\$L(let actual) = \$L {", "} else {", errorVariableName, operationErrorVariableName) {

        }
        writer.indent()
        writer.write("XCTFail(\"The deserialized error type does not match expected type\")")
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
