package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.SwiftDependency

object SmithyTestUtilTypes {
    val TestInitializer = runtimeSymbol("TestInitializer", SwiftDeclaration.ENUM)
    val TestBaseError = runtimeSymbol("TestBaseError")
    val SelectNoAuthScheme = runtimeSymbol("SelectNoAuthScheme")
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    SwiftDependency.SMITHY_TEST_UTIL,
    null,
)
