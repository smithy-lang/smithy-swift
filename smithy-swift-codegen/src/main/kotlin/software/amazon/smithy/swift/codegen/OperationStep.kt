package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol

abstract class OperationStep(outputType: Symbol, outputErrorType: Symbol) {
    abstract val inputType: Symbol
    val outputType: Symbol = Symbol
        .builder()
        .name("OperationOutput<$outputType, $outputErrorType>")
        .addDependency(SwiftDependency.CLIENT_RUNTIME)
        .build()
}
