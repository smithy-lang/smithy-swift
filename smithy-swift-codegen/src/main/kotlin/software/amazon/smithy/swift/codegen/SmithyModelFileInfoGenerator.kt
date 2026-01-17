package software.amazon.smithy.swift.codegen

import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.SerdeUtils

class SmithyModelFileInfoGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
) {
    fun writeSmithyModelFileInfo() {
        if (ctx.settings.moduleName.startsWith("Internal")) return
        val filename = "Sources/${ctx.settings.moduleName}/smithy-model-info.json"
        ctx.delegator.useFileWriter(filename) { writer ->
            val service = ctx.settings.service
            val path = ctx.settings.modelPath
            writer.openBlock("{", "}") {
                writer.write("\"service\": \"$service\",")
                writer.write("\"path\": \"$path\"")
            }
        }
    }
}
