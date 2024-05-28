package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.model.buildSymbol

object SmithyIdentityAPITypes {
    val AWSCredentialIdentityResolver = runtimeSymbol("AWSCredentialIdentityResolver")
}

private fun runtimeSymbol(name: String): Symbol = buildSymbol {
    this.name = name
    this.namespace = SwiftDependency.SMITHY_IDENTITY_API.target
    this.dependency(SwiftDependency.SMITHY_IDENTITY_API)
}
