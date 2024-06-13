package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.SwiftDependency

object CRT {
    val CommonRuntimeKit = runtimeSymbol("CommonRuntimeKit", SwiftDeclaration.STRUCT)
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null, spiName: String? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    SwiftDependency.CRT,
    spiName,
)
