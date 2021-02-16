package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol

abstract class Middleware(private val writer: SwiftWriter, shapeSymbol: Symbol, step: MiddlewareStep) {
    open val typeName: String = "${shapeSymbol.name}Middleware"

    open val inputType: Symbol = step.inputType

    open val outputType: Symbol = step.outputType

    open val contextType: Symbol = Symbol
        .builder()
        .name("HttpContext")
        .addDependency(SwiftDependency.CLIENT_RUNTIME)
        .build()

    open val typesToConformMiddlewareTo: List<String> = mutableListOf("Middleware")

    open val properties: MutableMap<String, Symbol> = mutableMapOf()

    fun getTypeInheritance(): String {
        val separator = if (typesToConformMiddlewareTo.count() == 1) "" else ", "
        return typesToConformMiddlewareTo.joinToString(separator)
    }

    abstract fun generateInit()

    open fun renderReturn() {
        writer.write("return next.handle(context: context, input: input)")
    }

    abstract fun generateMiddlewareClosure()
}

abstract class MiddlewareStep(outputType: Symbol, outputErrorType: Symbol) {
    abstract val inputType: Symbol
    val outputType: Symbol = Symbol
        .builder()
        .name("OperationOutput<$outputType, $outputErrorType>")
        .addDependency(SwiftDependency.CLIENT_RUNTIME)
        .build()
}
