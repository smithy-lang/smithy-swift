package software.amazon.smithy.swift.codegen.integration.steps

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.OperationStep

class OperationDeserializeStep(
    outputType: Symbol,
    outputErrorType: Symbol
) : OperationStep(outputType, outputErrorType) {
    override val inputType: Symbol = ClientRuntimeTypes.Http.SdkHttpRequest
}
