package software.amazon.smithy.swift.codegen.integration.steps

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.OperationStep
import software.amazon.smithy.swift.codegen.SwiftDependency

class OperationFinalizeStep(
    outputType: Symbol,
    outputErrorType: Symbol
) : OperationStep(outputType, outputErrorType) {
    override val inputType: Symbol = Symbol
        .builder()
        .name("SdkHttpRequestBuilder")
        .dependencies(SwiftDependency.CLIENT_RUNTIME)
        .build()
}
