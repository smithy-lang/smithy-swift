package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol

abstract class Middleware(private val writer: SwiftWriter, shapeSymbol: Symbol) {
    open val typeName: String = "${shapeSymbol.name}Middleware"

    abstract val inputType: Symbol

    abstract val outputType: Symbol

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
