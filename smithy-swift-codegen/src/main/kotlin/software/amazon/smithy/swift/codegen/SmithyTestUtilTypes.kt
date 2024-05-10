package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.model.buildSymbol

object SmithyTestUtilTypes {
    val TestBaseError = runtimeSymbol("TestBaseError")
}

private fun runtimeSymbol(name: String): Symbol = buildSymbol {
    this.name = name
    this.namespace = SwiftDependency.SMITHY_TEST_UTIL.target
    dependency(SwiftDependency.SMITHY_TEST_UTIL)
}
