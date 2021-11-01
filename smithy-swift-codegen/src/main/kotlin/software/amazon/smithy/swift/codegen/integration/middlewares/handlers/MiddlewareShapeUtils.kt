package software.amazon.smithy.swift.codegen.integration.middlewares.handlers

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.integration.isInHttpBody
import software.amazon.smithy.swift.codegen.model.capitalizedName

class MiddlewareShapeUtils {
    companion object {
        fun inputShape(model: Model, op: OperationShape): Shape {
            return model.expectShape(op.input.get())
        }
        fun inputSymbol(symbolProvider: SymbolProvider, model: Model, op: OperationShape): Symbol {
            val opIndex = OperationIndex.of(model)
            return inputSymbol(symbolProvider, opIndex, op)
        }
        fun inputSymbol(symbolProvider: SymbolProvider, opIndex: OperationIndex, op: OperationShape): Symbol {
            val inputShape = opIndex.getInput(op).get()
            return symbolProvider.toSymbol(inputShape)
        }
        fun outputSymbol(symbolProvider: SymbolProvider, model: Model, op: OperationShape): Symbol {
            val opIndex = OperationIndex.of(model)
            return outputSymbol(symbolProvider, opIndex, op)
        }
        fun outputSymbol(symbolProvider: SymbolProvider, opIndex: OperationIndex, op: OperationShape): Symbol {
            val outputShape = opIndex.getOutput(op).get()
            return symbolProvider.toSymbol(outputShape)
        }
        fun outputErrorSymbol(op: OperationShape): Symbol {
            val operationErrorName = outputErrorSymbolName(op)
            return Symbol.builder().name(operationErrorName).build()
        }
        fun outputErrorSymbolName(op: OperationShape): String {
            return "${op.capitalizedName()}OutputError"
        }
        fun rootNamespace(settings: SwiftSettings): String {
            return settings.moduleName
        }

        fun hasHttpBody(inputShape: Shape): Boolean {
            return inputShape.members().filter { it.isInHttpBody() }.count() > 0
        }
    }
}
