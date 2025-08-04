package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.SwiftDependency

object SmithyIdentityTypes {
    val AWSCredentialIdentityResolver =
        runtimeSymbol("AWSCredentialIdentityResolver", SwiftDeclaration.PROTOCOL, listOf("AWSCredentialIdentityResolver"))
    val BearerTokenIdentityResolver = runtimeSymbol("BearerTokenIdentityResolver", SwiftDeclaration.PROTOCOL)
    val BearerTokenIdentity = runtimeSymbol("BearerTokenIdentity", SwiftDeclaration.STRUCT)
    val StaticAWSCredentialIdentityResolver =
        runtimeSymbol("StaticAWSCredentialIdentityResolver", SwiftDeclaration.STRUCT, listOf("StaticAWSCredentialIdentityResolver"))
    val StaticBearerTokenIdentityResolver =
        runtimeSymbol("StaticBearerTokenIdentityResolver", SwiftDeclaration.STRUCT, listOf("StaticBearerTokenIdentityResolver"))
}

private fun runtimeSymbol(
    name: String,
    declaration: SwiftDeclaration? = null,
    spiNames: List<String> = listOf(),
): Symbol =
    SwiftSymbol.make(
        name,
        declaration,
        SwiftDependency.SMITHY_IDENTITY,
        emptyList(),
        spiNames,
    )
