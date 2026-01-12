package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.SwiftDependency

object RPCv2CBORTypes {
    val ClientProtocol = runtimeSymbol("ClientProtocol", SwiftDeclaration.STRUCT)
    val Codec = runtimeSymbol("Codec", SwiftDeclaration.STRUCT)
}

private fun runtimeSymbol(
    name: String,
    declaration: SwiftDeclaration?,
    additionalImports: List<Symbol> = emptyList(),
    spiName: List<String> = emptyList(),
): Symbol =
    SwiftSymbol.make(
        name,
        declaration,
        SwiftDependency.RPCV2CBOR,
        additionalImports,
        spiName,
    )
