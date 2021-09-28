package software.amazon.smithy.swift.codegen.middleware

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter

open class OperationMiddlewareGenerator(val mutableHashMap: MutableMap<OperationShape, MiddlewareStack> = mutableMapOf()) : OperationMiddleware {

    private var middlewareMap: MutableMap<OperationShape, MiddlewareStack> = mutableHashMap

    override fun appendMiddleware(operation: OperationShape, renderableMiddleware: MiddlewareRenderable) {
        val step = renderableMiddleware.middlewareStep
        val stack = middlewareMap.getOrPut(operation) { MiddlewareStack() }
        resolveStep(stack, step).add(renderableMiddleware)
    }

    override fun prependMiddleware(operation: OperationShape, renderableMiddleware: MiddlewareRenderable) {
        val step = renderableMiddleware.middlewareStep
        val stack = middlewareMap.getOrPut(operation) { MiddlewareStack() }
        resolveStep(stack, step).add(0, renderableMiddleware)
    }

    override fun removeMiddleware(operation: OperationShape, step: MiddlewareStep, middlewareName: String) {
        val stack = middlewareMap.getOrPut(operation) { MiddlewareStack() }
        resolveStep(stack, step).removeIf {
            it.name == middlewareName
        }
    }

    override fun clone(): OperationMiddleware {
        val copy: MutableMap<OperationShape, MiddlewareStack> = mutableMapOf()
        middlewareMap.forEach { (shape, stack) ->
            copy[shape] = MiddlewareStack(
                stack.initializeMiddlewares.toMutableList(),
                stack.serializeMiddlewares.toMutableList(),
                stack.buildMiddlewares.toMutableList(),
                stack.finalizeMiddlewares.toMutableList(),
                stack.deserializeMiddlewares.toMutableList()
            )
        }
        return OperationMiddlewareGenerator(copy)
    }

    override fun renderMiddleware(
        model: Model,
        symbolProvider: SymbolProvider,
        writer: SwiftWriter,
        operation: OperationShape,
        operationStackName: String,
        step: MiddlewareStep,
        executionContext: MiddlewareRenderableExecutionContext
    ) {
        val stack = middlewareMap.getOrPut(operation) { MiddlewareStack() }
        val step = resolveStep(stack, step)
        for (renderableMiddlware in step) {
            renderableMiddlware.render(model, symbolProvider, writer, operation, operationStackName, executionContext)
        }
    }

    private fun resolveStep(stack: MiddlewareStack, step: MiddlewareStep): MutableList<MiddlewareRenderable> {
        return when (step) {
            MiddlewareStep.INITIALIZESTEP -> stack.initializeMiddlewares
            MiddlewareStep.BUILDSTEP -> stack.buildMiddlewares
            MiddlewareStep.SERIALIZESTEP -> stack.serializeMiddlewares
            MiddlewareStep.FINALIZESTEP -> stack.finalizeMiddlewares
            MiddlewareStep.DESERIALIZESTEP -> stack.deserializeMiddlewares
        }
    }
}
