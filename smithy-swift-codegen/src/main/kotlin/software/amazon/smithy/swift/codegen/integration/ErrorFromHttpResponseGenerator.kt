package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape

interface ErrorFromHttpResponseGenerator {
    fun generateInitOperationFromHttpResponse(ctx: ProtocolGenerator.GenerationContext, op: OperationShape, unknownServiceErrorSymbol: Symbol)
}
