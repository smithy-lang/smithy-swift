package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.Dependency
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.model.buildSymbol

class SwiftSymbol {

    companion object {
        fun make(
            name: String,
            declaration: SwiftDeclaration?,
            dependency: Dependency?,
        ): Symbol = buildSymbol {
            this.name = name
            declaration?.let { this.setProperty("decl", it.keyword) }
            dependency?.let {
                this.namespace = it.target
                this.dependency(it)
            }
        }
    }
}
