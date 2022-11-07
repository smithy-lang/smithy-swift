package software.amazon.smithy.swift.codegen.integration.middlewares.handlers

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.HttpTrait
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.isInHttpBody
import software.amazon.smithy.swift.codegen.model.toUpperCamelCase
import software.amazon.smithy.swift.codegen.model.getTrait

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
            return "${op.toUpperCamelCase()}OutputError"
        }
        fun rootNamespace(settings: SwiftSettings): String {
            return settings.moduleName
        }

        fun hasHttpBody(model: Model, op: OperationShape): Boolean {
            val inputShape = inputShape(model, op)
            return inputShape.members().any { it.isInHttpBody() }
        }

        fun bodyIsHttpPayload(model: Model, op: OperationShape): Boolean {
            // a special type in smithy where body only has one member and is typically bytes
            val bindingIndex = HttpBindingIndex.of(model)
            val requestBindings = bindingIndex.getRequestBindings(op).values.map { HttpBindingDescriptor(it) }
            return requestBindings.firstOrNull { it.location == HttpBinding.Location.PAYLOAD } != null
        }

        fun hasHttpHeaders(model: Model, op: OperationShape): Boolean {
            val bindingIndex = HttpBindingIndex.of(model)
            val requestBindings = bindingIndex.getRequestBindings(op).values.map { HttpBindingDescriptor(it) }
            val headerBindings = requestBindings
                .filter { it.location == HttpBinding.Location.HEADER }
                .sortedBy { it.memberName }
            val prefixHeaderBindings = requestBindings
                .filter { it.location == HttpBinding.Location.PREFIX_HEADERS }
            return headerBindings.isNotEmpty() || prefixHeaderBindings.isNotEmpty()
        }

        fun hasQueryItems(model: Model, op: OperationShape): Boolean {
            val bindingIndex = HttpBindingIndex.of(model)
            val httpTrait = op.getTrait<HttpTrait>()
            val requestBindings = bindingIndex.getRequestBindings(op).values.map { HttpBindingDescriptor(it) }
            val queryBindings =
                requestBindings.filter { it.location == HttpBinding.Location.QUERY || it.location == HttpBinding.Location.QUERY_PARAMS }
            val queryLiterals = httpTrait?.uri?.queryLiterals
            return queryBindings.isNotEmpty() || !queryLiterals.isNullOrEmpty()
        }
    }
}
