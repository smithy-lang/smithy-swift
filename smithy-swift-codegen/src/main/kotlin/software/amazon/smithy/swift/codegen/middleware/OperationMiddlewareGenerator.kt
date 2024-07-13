package software.amazon.smithy.swift.codegen.middleware

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

open class OperationMiddlewareGenerator(
    mutableHashMap: MutableMap<OperationShape, MutableList<MiddlewareRenderable>> = mutableMapOf()
) : OperationMiddleware {

    private var middlewareMap: MutableMap<OperationShape, MutableList<MiddlewareRenderable>> = mutableHashMap

    override fun appendMiddleware(operation: OperationShape, renderableMiddleware: MiddlewareRenderable) {
        middlewareMap.getOrPut(operation) { mutableListOf() }.add(renderableMiddleware)
    }

    override fun prependMiddleware(operation: OperationShape, renderableMiddleware: MiddlewareRenderable) {
        middlewareMap.getOrPut(operation) { mutableListOf() }.add(0, renderableMiddleware)
    }

    override fun removeMiddleware(operation: OperationShape, middlewareName: String) {
        val opMiddleware = middlewareMap.getOrPut(operation) { mutableListOf() }
        opMiddleware.removeIf { it.name == middlewareName }
    }

    override fun middlewares(operation: OperationShape): List<MiddlewareRenderable> {
        return middlewareMap.getOrPut(operation) { mutableListOf() }
    }

    override fun clone(): OperationMiddleware {
        val copy: MutableMap<OperationShape, MutableList<MiddlewareRenderable>> = mutableMapOf()
        middlewareMap.forEach { (shape, list) ->
            copy[shape] = list.toMutableList()
        }
        return OperationMiddlewareGenerator(copy)
    }

    override fun renderMiddleware(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        operation: OperationShape,
        operationStackName: String,
    ) {
        val opMiddleware = middlewareMap.getOrPut(operation) { mutableListOf() }
        for (renderableMiddleware in opMiddleware) {
            renderableMiddleware.render(ctx, writer, operation, operationStackName)
        }
    }
}
