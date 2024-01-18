package software.amazon.smithy.swift.codegen.integration.plugins

import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.Plugin

enum class DefaultPlugins(override val className: String) : Plugin {
    DefaultClientPlugin("DefaultClientPlugin") {
        override fun addImport(writer: SwiftWriter) {
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
        }
    }
}
