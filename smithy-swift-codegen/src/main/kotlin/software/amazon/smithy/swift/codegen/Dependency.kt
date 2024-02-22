package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.SymbolDependencyContainer

interface Dependency : SymbolDependencyContainer {
    val target: String
    var packageName: String
}
