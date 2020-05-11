package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.codegen.core.SymbolDependencyContainer

enum class SwiftDependency(val type: String, val namespace: String, val version: String) : SymbolDependencyContainer {
    BIG("pod", "BigNumber", "2.0");

    override fun getDependencies(): List<SymbolDependency> {
        val dependency = SymbolDependency.builder()
            .dependencyType(type)
            .packageName(namespace)
            .version(version)
            .build()
        return listOf(dependency)
    }
}
