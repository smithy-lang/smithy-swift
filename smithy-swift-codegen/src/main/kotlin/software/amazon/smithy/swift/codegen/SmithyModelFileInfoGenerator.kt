package software.amazon.smithy.swift.codegen

import software.amazon.smithy.aws.traits.ServiceTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.getTrait

class SmithyModelFileInfoGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
) {
    fun writeSmithyModelFileInfo() {
        ctx.service.getTrait<ServiceTrait>()?.let { serviceTrait ->
            val filename = "Sources/${ctx.settings.moduleName}/smithy-model-file-info.txt"
            val modelFileName = serviceTrait
                .sdkId
                .lowercase()
                .replace(",", "")
                .replace(" ", "-")
            val contents = "codegen/sdk-codegen/aws-models/$modelFileName.json"
            ctx.delegator.useFileWriter(filename) { writer ->
                writer.write(contents)
            }
        }
    }
}
