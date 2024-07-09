package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.model.buildSymbol

object SmithyTestUtilTypes {
    val TestInitializer = runtimeSymbol("TestInitializer")
    val TestBaseError = runtimeSymbol("TestBaseError")
    val SelectNoAuthScheme = runtimeSymbol("SelectNoAuthScheme")
}

private fun runtimeSymbol(name: String): Symbol = buildSymbol {
    this.name = name
    this.namespace = SwiftDependency.SMITHY_TEST_UTIL.target
    dependency(SwiftDependency.SMITHY_TEST_UTIL)
}
