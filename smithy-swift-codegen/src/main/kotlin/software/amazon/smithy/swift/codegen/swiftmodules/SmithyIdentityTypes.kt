package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.model.buildSymbol

object SmithyIdentityTypes {
    val AWSCredentialIdentityResolver = runtimeSymbol("AWSCredentialIdentityResolver")
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null): Symbol = buildSymbol {
    this.name = name
    this.namespace = SwiftDependency.SMITHY_IDENTITY.target
    declaration?.let { this.setProperty("decl", it.keyword) }
    dependency(SwiftDependency.SMITHY_IDENTITY_API)
}
