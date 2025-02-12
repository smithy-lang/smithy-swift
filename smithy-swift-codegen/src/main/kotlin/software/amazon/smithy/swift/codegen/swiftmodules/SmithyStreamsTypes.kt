package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.SwiftDependency

object SmithyStreamsTypes {
    object Core {
        val BufferedStream = runtimeSymbol("BufferedStream", SwiftDeclaration.CLASS)
    }
}

private fun runtimeSymbol(
    name: String,
    declaration: SwiftDeclaration? = null,
): Symbol =
    SwiftSymbol.make(
        name,
        declaration,
        SwiftDependency.SMITHY_STREAMS,
        emptyList(),
        emptyList(),
    )
