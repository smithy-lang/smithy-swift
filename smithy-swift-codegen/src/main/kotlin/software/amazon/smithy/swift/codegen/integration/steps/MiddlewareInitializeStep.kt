package software.amazon.smithy.swift.codegen.integration.steps

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.MiddlewareStep

class MiddlewareInitializeStep(
    inputType: Symbol,
    outputType: Symbol,
    outputErrorType: Symbol
) : MiddlewareStep(outputType, outputErrorType) {
    override val inputType: Symbol = inputType
}
