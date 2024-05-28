package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.model.buildSymbol

/**
 * Commonly used runtime types. Provides a single definition of a runtime symbol such that codegen isn't littered
 * with inline symbol creation which makes refactoring of the runtime more difficult and error prone.
 *
 * NOTE: Not all symbols need be added here but it doesn't hurt to define runtime symbols once.
 */
object SmithyTypes {
    val ClientError = runtimeSymbol("ClientError")
    val Context = runtimeSymbol("Context")
    val ContextBuilder = runtimeSymbol("ContextBuilder")
    val LogAgent = runtimeSymbol("LogAgent")
}

private fun runtimeSymbol(name: String): Symbol = buildSymbol {
    this.name = name
    this.namespace = SwiftDependency.SMITHY.target
    this.dependency(SwiftDependency.SMITHY)
}
