/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.model

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.removeSurroundingBackticks

/**
 * Property bag keys used by symbol provider implementation
 */
object SymbolProperty {
    // Entry type for Maps
    const val ENTRY_EXPRESSION: String = "entryExpression"

    // The key that holds the default value for a type (symbol) as a string
    const val DEFAULT_VALUE_KEY: String = "defaultValue"

    // The key that holds the default value closure for a type (symbol) that returns a string
    const val DEFAULT_VALUE_CLOSURE_KEY: String = "defaultValueClosure"

    // Boolean property indicating this symbol should be boxed
    const val BOXED_KEY: String = "boxed"

    const val NESTED_SYMBOL: String = "nestedSymbol"
}

/**
 * Test if a symbol is boxed or not
 */
fun Symbol.isBoxed(): Boolean {
    return getProperty(SymbolProperty.BOXED_KEY).map {
        when (it) {
            is Boolean -> it
            else -> false
        }
    }.orElse(false)
}

/**
 * Gets the default value for the symbol if present, else null
 */
fun Symbol.defaultValue(): String? {
    val default = getProperty(SymbolProperty.DEFAULT_VALUE_KEY, String::class.java)

    // If shape is boxed (nullable) AND there is no default value set, return nil as default value
    if (isBoxed() && !default.isPresent) {
        return "nil"
    }

    // If default value is present, return default value. Otherwise, return null
    return if (default.isPresent) default.get() else null
}

/**
 * Gets the default value for the symbol by processing closure if present, else null
 */
fun Symbol.defaultValueFromClosure(writer: SwiftWriter): String? {
    val default = getProperty(SymbolProperty.DEFAULT_VALUE_CLOSURE_KEY)

    // If shape is boxed (nullable) AND there is no default value set, return nil as default value
    if (isBoxed() && !default.isPresent) {
        return "nil"
    }

    // Suppress the warning and force-cast the closure to the expected type
    @Suppress("UNCHECKED_CAST")
    return if (default.isPresent) {
        val closure = default.get() as Function1<SwiftWriter, String>
        closure(writer)
    } else null
}

/**
 * Mark a symbol as being boxed (nullable) i.e. `T?`
 */
fun Symbol.Builder.boxed(): Symbol.Builder = apply { putProperty(SymbolProperty.BOXED_KEY, true) }

/**
 * Set the default value used when formatting the symbol
 */
fun Symbol.Builder.defaultValue(value: String): Symbol.Builder = apply { putProperty(SymbolProperty.DEFAULT_VALUE_KEY, value) }

/**
 * Set the closure that gets called with a SwiftWriter to import symbols needed for default value
 * Used in SwiftSymbolProvider (which doesn't have access to SwiftWriter).
 * Allows default value of a symbol X returned by SwiftSymbolProvider to have needed imports
 *      for symbol Y at the time symbol X is printed by SwiftWriter.
 *
 * Example: Default value for a symbol called X could be "Data()", which means when the symbol X is printed by SwiftWriter,
 *      we need to import Foundation.Data.
 */
fun Symbol.Builder.defaultValueClosure(closure: (SwiftWriter) -> String): Symbol.Builder = apply {
    putProperty(SymbolProperty.DEFAULT_VALUE_CLOSURE_KEY, closure)
}

fun SymbolProvider.toMemberNames(shape: MemberShape): Pair<String, String> {
    val escapedName = toMemberName(shape)
    return Pair(escapedName, escapedName.removeSurroundingBackticks())
}

val Symbol.isBuiltIn: Boolean
    get() = namespace == "Swift"

val Symbol.isServiceNestedNamespace: Boolean
    get() = namespace.endsWith("Types")
