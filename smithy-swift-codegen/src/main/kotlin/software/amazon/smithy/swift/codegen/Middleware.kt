/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes

abstract class Middleware(private val writer: SwiftWriter, shapeSymbol: Symbol, step: OperationStep) {
    open val id: String get() = typeName
    open val typeName: String = "${shapeSymbol.name}Middleware"

    open val inputType: Symbol = step.inputType

    open val outputType: Symbol = step.outputType

    open val typesToConformMiddlewareTo: List<Symbol> = mutableListOf(ClientRuntimeTypes.Middleware.Middleware)

    open val properties: MutableMap<String, Symbol> = mutableMapOf()

    abstract fun generateInit()

    open fun renderReturn() {
        writer.write("return try await next.handle(context: context, input: input)")
    }

    /**
     * Called after rendering the middleware struct, used for writing extensions
     * (although you can technically put anything here)
     */
    open fun renderExtensions() {}

    abstract fun generateMiddlewareClosure()
}
