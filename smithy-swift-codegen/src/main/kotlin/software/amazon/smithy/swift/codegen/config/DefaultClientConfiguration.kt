package software.amazon.smithy.swift.codegen.config

import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter

class DefaultClientConfiguration : ClientConfiguration {
    override val swiftProtocolName: String
        get() = "DefaultClientConfiguration"

    override fun addImport(writer: SwiftWriter) {
        writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
    }
}
