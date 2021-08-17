/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol

abstract class Middleware(private val writer: SwiftWriter, shapeSymbol: Symbol, step: OperationStep) {
    open val typeName: String = "${shapeSymbol.name}Middleware"

    open val inputType: Symbol = step.inputType

    open val outputType: Symbol = step.outputType

    open val errorType: Symbol = step.errorType

    open val contextType: Symbol = Symbol
        .builder()
        .name("HttpContext")
        .namespace(SwiftDependency.CLIENT_RUNTIME.target, ".")
        .addDependency(SwiftDependency.CLIENT_RUNTIME)
        .build()

    open val typesToConformMiddlewareTo: List<Symbol> = mutableListOf(ClientRuntimeTypes.Middleware.Middleware)

    open val properties: MutableMap<String, Symbol> = mutableMapOf()

    fun getTypeInheritance(): String {
        val separator = if (typesToConformMiddlewareTo.count() == 1) "" else ", "
        return typesToConformMiddlewareTo.joinToString(separator) { it.toString() }
    }

    abstract fun generateInit()

    open fun renderReturn() {
        writer.write("return next.handle(context: context, input: input)")
    }

    abstract fun generateMiddlewareClosure()
}
