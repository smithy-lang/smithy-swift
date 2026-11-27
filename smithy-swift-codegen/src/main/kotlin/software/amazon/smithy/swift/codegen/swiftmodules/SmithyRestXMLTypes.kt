package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.SwiftDependency

object SmithyRestXMLTypes {
    val HTTPClientProtocol = runtimeSymbol("HTTPClientProtocol", SwiftDeclaration.STRUCT)
}

private fun runtimeSymbol(
    name: String,
    declaration: SwiftDeclaration?,
    additionalImports: List<Symbol> = emptyList(),
    spiName: List<String> = listOf("SchemaBasedSerde"),
): Symbol =
    SwiftSymbol.make(
        name,
        declaration,
        SwiftDependency.SMITHY_RESTXML,
        additionalImports,
        spiName,
    )
