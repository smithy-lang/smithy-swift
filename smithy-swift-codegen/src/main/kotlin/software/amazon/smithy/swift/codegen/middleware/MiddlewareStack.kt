package software.amazon.smithy.swift.codegen.middleware

data class MiddlewareStack(
    var initializeMiddlewares: MutableList<MiddlewareRenderable> = mutableListOf(),
    var serializeMiddlewares: MutableList<MiddlewareRenderable> = mutableListOf(),
    var buildMiddlewares: MutableList<MiddlewareRenderable> = mutableListOf(),
    var finalizeMiddlewares: MutableList<MiddlewareRenderable> = mutableListOf(),
    var deserializeMiddlewares: MutableList<MiddlewareRenderable> = mutableListOf(),
)
