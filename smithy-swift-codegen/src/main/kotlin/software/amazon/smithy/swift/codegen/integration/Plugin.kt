package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftWriter

interface Plugin {
    val className: Symbol
    val isDefault: Boolean
        get() = false

    fun customInitialization(writer: SwiftWriter) {
        writer.writeInline("\$L()", className)
    }

    fun render(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter) {
    }
}
