package software.amazon.smithy.swift.codegen

import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class SmithyModelFileInfoGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
) {
    fun writeSmithyModelFileInfo() {
        val filename = "Sources/${ctx.settings.moduleName}/smithy-model-info.json"
        ctx.delegator.useFileWriter(filename) { writer ->
            val service = ctx.settings.service
            val path = ctx.settings.modelPath
            writer.openBlock("{", "}") {
                writer.write("\"service\": \"$service\",")
                writer.write("\"path\": \"$path\",")
                val operations = ctx.settings.operations
                if (ctx.settings.internalClient) {
                    writer.write("\"internal\": true,")
                }
                if (operations.isNotEmpty()) {
                    writer.write(
                        "\"operations\": [\$L],",
                        operations.map { "\"$it\"" }.joinToString(", "),
                    )
                }
                writer.unwrite(",\n")
                writer.write("\n")
            }
        }
    }
}
