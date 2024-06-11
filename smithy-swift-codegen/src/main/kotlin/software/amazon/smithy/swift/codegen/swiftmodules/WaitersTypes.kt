package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.SwiftDependency

object WaitersTypes {
    val Waiter = runtimeSymbol("Waiter", SwiftDeclaration.CLASS)
    val WaiterConfiguration = runtimeSymbol("WaiterConfiguration", SwiftDeclaration.STRUCT)
    val WaiterOptions = runtimeSymbol("WaiterOptions", SwiftDeclaration.STRUCT)
    val WaiterOutcome = runtimeSymbol("WaiterOutcome", SwiftDeclaration.STRUCT)
    val JMESUtils = runtimeSymbol("JMESUtils", SwiftDeclaration.ENUM)
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    SwiftDependency.CLIENT_RUNTIME,
    null,
)
