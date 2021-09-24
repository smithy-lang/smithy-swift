package software.amazon.smithy.swift.codegen.middleware

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter

interface OperationMiddleware {
    fun appendMiddleware(operation: OperationShape, renderableMiddleware: MiddlewareRenderable)
    fun prependMiddleware(operation: OperationShape, renderableMiddleware: MiddlewareRenderable)
    fun removeMiddleware(operation: OperationShape, step: MiddlewareStep, middlewareName: String)

    fun clone(): OperationMiddleware

    fun renderMiddleware(
        model: Model,
        symbolProvider: SymbolProvider,
        writer: SwiftWriter,
        operation: OperationShape,
        operationStackName: String,
        step: MiddlewareStep,
        executionContext: MiddlewareRenderableExecutionContext
    )
}
