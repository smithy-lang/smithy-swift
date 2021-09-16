package software.amazon.smithy.swift.codegen.middleware

import software.amazon.smithy.swift.codegen.integration.OperationMiddlewareRenderable

data class MiddlewareStack(
    var initializeMiddlewares: MutableList<OperationMiddlewareRenderable> = mutableListOf(),
    var serializeMiddlewares: MutableList<OperationMiddlewareRenderable> = mutableListOf(),
    var buildMiddlewares: MutableList<OperationMiddlewareRenderable> = mutableListOf(),
    var finalizeMiddlewares: MutableList<OperationMiddlewareRenderable> = mutableListOf(),
    var deserializeMiddlewares: MutableList<OperationMiddlewareRenderable> = mutableListOf(),
)
