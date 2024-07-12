package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.SwiftDependency

object SmithyIdentityTypes {
    val AWSCredentialIdentityResolver = runtimeSymbol("AWSCredentialIdentityResolver", SwiftDeclaration.PROTOCOL)
    val BearerTokenIdentityResolver = runtimeSymbol("BearerTokenIdentityResolver", SwiftDeclaration.PROTOCOL)
    val StaticBearerTokenIdentityResolver = runtimeSymbol("StaticBearerTokenIdentityResolver", SwiftDeclaration.STRUCT)
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    SwiftDependency.SMITHY_IDENTITY,
    null,
)
