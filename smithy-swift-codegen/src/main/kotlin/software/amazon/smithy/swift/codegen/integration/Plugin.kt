package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.swift.codegen.SwiftWriter

interface Plugin {
    val className: String
    fun addImport(writer: SwiftWriter)
}
