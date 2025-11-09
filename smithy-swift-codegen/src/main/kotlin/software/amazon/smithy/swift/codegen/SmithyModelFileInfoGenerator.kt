package software.amazon.smithy.swift.codegen

import software.amazon.smithy.aws.traits.ServiceTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.expectTrait

class SmithyModelFileInfoGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
) {
    fun writeSmithyModelFileInfo() {
        val model = ctx.service.expectTrait<ServiceTrait>().sdkId
            .replace(",", "")
            .lowercase()
            .replace(" ", "-")
        ctx.delegator.useFileWriter("Sources/${ctx.settings.moduleName}/smithy-model-file-info.txt") { writer ->
            writer.write("codegen/sdk-codegen/aws-models/${model}.json")
        }
    }
}