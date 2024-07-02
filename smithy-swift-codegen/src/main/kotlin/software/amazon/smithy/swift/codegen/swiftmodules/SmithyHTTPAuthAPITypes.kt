package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.SwiftDependency

/**
 * Commonly used runtime types. Provides a single definition of a runtime symbol such that codegen isn't littered
 * with inline symbol creation which makes refactoring of the runtime more difficult and error prone.
 *
 * NOTE: Not all symbols need be added here but it doesn't hurt to define runtime symbols once.
 */
object SmithyHTTPAuthAPITypes {
    val AuthOption = runtimeSymbol("AuthOption", SwiftDeclaration.STRUCT)
    val AuthScheme = runtimeSymbol("AuthScheme", SwiftDeclaration.PROTOCOL)
    val AuthSchemes = runtimeSymbol("AuthSchemes", SwiftDeclaration.TYPEALIAS)
    val AuthSchemeResolver = runtimeSymbol("AuthSchemeResolver", SwiftDeclaration.PROTOCOL)
    val AuthSchemeResolverParams = runtimeSymbol("AuthSchemeResolverParameters", SwiftDeclaration.PROTOCOL)
    var SigningPropertyKeys = runtimeSymbol("SigningPropertyKeys", SwiftDeclaration.ENUM)
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    SwiftDependency.SMITHY_HTTP_AUTH_API,
    null,
)

private fun runtimeSymbolWithoutNamespace(name: String, declaration: SwiftDeclaration? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    null,
    null,
)
