package software.amazon.smithy.swift.codegen

import software.amazon.smithy.build.PluginContext
import software.amazon.smithy.build.SmithyBuildPlugin
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model

class SwiftCodegenPlugin : SmithyBuildPlugin {
    override fun getName(): String {
        return "swift-codegen"
    }

    override fun execute(context: PluginContext?) {
        print("not executed yet")
    }

    fun createSymbolProvider(model: Model): SymbolProvider {
        return SymbolVisitor(model)
    }
}