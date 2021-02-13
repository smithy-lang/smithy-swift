package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.shapes.OperationShape

interface ErrorFromHttpResponseGenerator {
    fun generateInitOperationFromHttpResponse(ctx: ProtocolGenerator.GenerationContext, op: OperationShape)
}

class EmptyErrorFromHttpResponseGenerator : ErrorFromHttpResponseGenerator {
    override fun generateInitOperationFromHttpResponse(ctx: ProtocolGenerator.GenerationContext, op: OperationShape) {
    }
}
