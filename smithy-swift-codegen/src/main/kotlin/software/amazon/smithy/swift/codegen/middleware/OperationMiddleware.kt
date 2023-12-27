package software.amazon.smithy.swift.codegen.middleware

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

interface OperationMiddleware {
    fun appendMiddleware(operation: OperationShape, renderableMiddleware: MiddlewareRenderable)
    fun prependMiddleware(operation: OperationShape, renderableMiddleware: MiddlewareRenderable)
    fun removeMiddleware(operation: OperationShape, step: MiddlewareStep, middlewareName: String)
    fun middlewares(operation: OperationShape, step: MiddlewareStep): List<MiddlewareRenderable>

    fun clone(): OperationMiddleware

    fun renderMiddleware(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        operation: OperationShape,
        operationStackName: String,
        step: MiddlewareStep
    )
}
