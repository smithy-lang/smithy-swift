package software.amazon.smithy.swift.codegen.integration.steps

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.OperationStep

class OperationInitializeStep(
    inputType: Symbol,
    outputType: Symbol,
    outputErrorType: Symbol
) : OperationStep(outputType, outputErrorType) {
    override val inputType: Symbol = inputType
}
