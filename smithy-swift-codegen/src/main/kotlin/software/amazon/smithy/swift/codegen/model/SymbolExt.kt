package software.amazon.smithy.swift.codegen.model

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.removeSurroundingBackticks

/**
 * Property bag keys used by symbol provider implementation
 */
object SymbolProperty {
    // The key that holds the default value for a type (symbol) as a string
    const val DEFAULT_VALUE_KEY: String = "defaultValue"

    // Boolean property indicating this symbol should be boxed
    const val BOXED_KEY: String = "boxed"
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
 * Obtains the symbol for a recursive symbol to represent the symbol as Box<T>
 */
fun Symbol.recursiveSymbol(): Symbol {
    return Symbol.builder()
        .addDependency(SwiftDependency.CLIENT_RUNTIME)
        .name("Box<$fullName>")
        .putProperty("boxed", isBoxed())
        .putProperty("defaultValue", defaultValue())
        .build()
}

/**
 * Gets the default value for the symbol if present, else null
 */
fun Symbol.defaultValue(): String? {
    // boxed types should always be defaulted to null
    if (isBoxed()) {
        return "nil"
    }

    val default = getProperty(SymbolProperty.DEFAULT_VALUE_KEY, String::class.java)
    return if (default.isPresent) default.get() else null
}

fun Symbol.bodySymbol(): Symbol {
    return Symbol.builder()
        .name("${name}Body")
        .putProperty("boxed", isBoxed())
        .putProperty("defaultValue", defaultValue())
        .build()
}

/**
 * Mark a symbol as being boxed (nullable) i.e. `T?`
 */
fun Symbol.Builder.boxed(): Symbol.Builder = apply { putProperty(SymbolProperty.BOXED_KEY, true) }

/**
 * Set the default value used when formatting the symbol
 */
fun Symbol.Builder.defaultValue(value: String): Symbol.Builder = apply { putProperty(SymbolProperty.DEFAULT_VALUE_KEY, value) }

fun SymbolProvider.toMemberNames(shape: MemberShape): Pair<String, String> {
    val escapedName = toMemberName(shape)
    return Pair(escapedName, escapedName.removeSurroundingBackticks())
}

val Symbol.isBuiltIn: Boolean
    get() = namespace == "Swift"

val Symbol.isServiceNestedNamespace: Boolean
    get() = namespace.endsWith("Types")
