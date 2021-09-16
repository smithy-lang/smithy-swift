package software.amazon.smithy.swift.codegen.middleware

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.OperationMiddlewareRenderable
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

open class OperationMiddlewareGenerator : OperationMiddleware {

    private var middlewareMap: MutableMap<OperationShape, MiddlewareStack> = mutableMapOf()

    override fun appendMiddleware(operation: OperationShape, renderableMiddleware: OperationMiddlewareRenderable) {
        val step = renderableMiddleware.middlewareStep
        val stack = middlewareMap.getOrPut(operation) { MiddlewareStack() }
        resolveStep(stack, step).add(renderableMiddleware)
    }

    override fun prependMiddleware(operation: OperationShape, renderableMiddleware: OperationMiddlewareRenderable) {
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

    override fun renderMiddleware(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        serviceShape: ServiceShape,
        operation: OperationShape,
        operationStackName: String,
        step: MiddlewareStep,
        callback: RenderMiddlewareCallback
    ) {
        val stack = middlewareMap.getOrPut(operation) { MiddlewareStack() }
        val step = resolveStep(stack, step)
        for (renderableMiddlware in step) {
            writer.putContext("ctx", ctx)
            writer.putContext("serviceShape", serviceShape)
            writer.putContext("operation", operation)
            writer.putContext("operationStackName", operationStackName)
            val shouldRender = callback(writer, renderableMiddlware)
            if (shouldRender) {
                renderableMiddlware.render(ctx, writer, serviceShape, operation, operationStackName)
            }
        }
    }

    private fun resolveStep(stack: MiddlewareStack, step: MiddlewareStep): MutableList<OperationMiddlewareRenderable> {
        return when (step) {
            MiddlewareStep.INITIALIZESTEP -> stack.initializeMiddlewares
            MiddlewareStep.BUILDSTEP -> stack.buildMiddlewares
            MiddlewareStep.SERIALIZESTEP -> stack.serializeMiddlewares
            MiddlewareStep.FINALIZESTEP -> stack.finalizeMiddlewares
            MiddlewareStep.DESERIALIZESTEP -> stack.deserializeMiddlewares
        }
    }
}
