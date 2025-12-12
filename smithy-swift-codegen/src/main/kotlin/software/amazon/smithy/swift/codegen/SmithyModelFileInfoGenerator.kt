package software.amazon.smithy.swift.codegen

import software.amazon.smithy.aws.traits.ServiceTrait
import software.amazon.smithy.swift.codegen.core.GenerationContext
import software.amazon.smithy.swift.codegen.model.getTrait

class SmithyModelFileInfoGenerator(
    val ctx: GenerationContext,
) {
    fun writeSmithyModelFileInfo() {
        ctx.model.serviceShapes.firstOrNull()?.getTrait<ServiceTrait>()?.let { serviceTrait ->
            val filename = "Sources/${ctx.settings.moduleName}/smithy-model-info.json"
            val modelFileName =
                serviceTrait
                    .sdkId
                    .lowercase()
                    .replace(",", "")
                    .replace(" ", "-")
            val contents = "codegen/sdk-codegen/aws-models/$modelFileName.json"
            ctx.writerDelegator().useFileWriter(filename) { writer ->
                writer.write("{\"path\":\"$contents\"}")
            }
        }
    }
}
