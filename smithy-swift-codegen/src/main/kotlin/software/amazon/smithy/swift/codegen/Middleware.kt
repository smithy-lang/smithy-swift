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

    abstract val properties: MutableMap<String, Symbol>

    fun getTypeInheritance(): String {
        if (typesToConformMiddlewareTo.count() == 1) {
            return typesToConformMiddlewareTo.joinToString("")
        } else {
            return typesToConformMiddlewareTo.joinToString(", ")
        }
    }

    open fun generateInit() {
        // pass none needed unless init should be public as struct has built in init
    }

    open fun generateMiddlewareClosure() {
        writer.write("return next.handle(context: context, input: input)")
    }
}