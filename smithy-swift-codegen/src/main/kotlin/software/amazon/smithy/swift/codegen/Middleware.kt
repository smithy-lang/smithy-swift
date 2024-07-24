/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol

abstract class Middleware(private val writer: SwiftWriter, shapeSymbol: Symbol) {
    open val id: String get() = typeName
    open val typeName: String = "${shapeSymbol.name}Middleware"
    open val properties: MutableMap<String, Symbol> = mutableMapOf()

    abstract fun generateInit()

    /**
     * Called after rendering the middleware struct, used for writing extensions
     * (although you can technically put anything here)
     */
    open fun renderExtensions() {}
}
