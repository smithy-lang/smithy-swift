package software.amazon.smithy.swift.codegen.integration.middlewares.handlers

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class MiddlewareHandlerUtils {
    companion object {
        fun inputSymbol(ctx: ProtocolGenerator.GenerationContext, op: OperationShape): Symbol {
            val opIndex = OperationIndex.of(ctx.model)
            val inputShape = opIndex.getInput(op).get()
            return ctx.symbolProvider.toSymbol(inputShape)
        }

        fun outputSymbol(ctx: ProtocolGenerator.GenerationContext, op: OperationShape): Symbol {
            val opIndex = OperationIndex.of(ctx.model)
            val outputShape = opIndex.getOutput(op).get()
            return ctx.symbolProvider.toSymbol(outputShape)
        }

        fun outputErrorSymbol(op: OperationShape): Symbol {
            val operationErrorName = ServiceGenerator.getOperationErrorShapeName(op)
            return Symbol.builder().name(operationErrorName).build()
        }
        fun rootNamespace(ctx: ProtocolGenerator.GenerationContext): String {
            return ctx.settings.moduleName
        }
    }
}
