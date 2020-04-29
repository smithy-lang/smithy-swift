package software.amazon.smithy.swift.codegen

import software.amazon.smithy.build.PluginContext
import software.amazon.smithy.build.SmithyBuildPlugin
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model

class SwiftCodegenPlugin : SmithyBuildPlugin {

    companion object {
        fun createSymbolProvider(model: Model):SymbolProvider = SymbolVisitor(model)

    }

    override fun getName(): String = "swift-codegen"

    override fun execute(context: PluginContext?) {
        println("executing swift codegen")

        CodegenVisitor(context!!).execute()
    }
}