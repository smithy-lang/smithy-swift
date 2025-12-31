package software.amazon.smithy.swift.codegen

import software.amazon.smithy.swift.codegen.core.GenerationContext

class SmithyModelFileInfoGenerator(
    val ctx: GenerationContext,
) {
    fun writeSmithyModelFileInfo() {
        val filename = "Sources/${ctx.settings.moduleName}/smithy-model-info.json"
        ctx.writerDelegator().useFileWriter(filename) { writer ->
            val service = ctx.settings.service
            val path = ctx.settings.modelPath
            val settingsSdkId = ctx.settings.sdkId
            writer.openBlock("{", "}") {
                writer.write("\"service\": \"$service\",")
                writer.write("\"path\": \"$path\",")
                writer.write("\"settingsSdkId\": \"$settingsSdkId\"")
            }
        }
    }
}
