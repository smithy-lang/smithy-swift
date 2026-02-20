package software.amazon.smithy.swift.codegen

import software.amazon.smithy.model.node.ArrayNode
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.node.ObjectNode
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.SerdeUtils

class SwiftSettingsJSONGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
) {
    fun render() {
        if (!SerdeUtils.useSchemaBased(ctx)) return
        ctx.delegator.useFileWriter("Sources/${ctx.settings.moduleName}/swift-settings.json") { writer ->
            val node =
                ObjectNode
                    .builder()
                    .withMember(SwiftSettings.SERVICE, ctx.settings.service.toString())
                    .withMember(SwiftSettings.MODULE_NAME, ctx.settings.moduleName)
                    .withMember(SwiftSettings.MODULE_VERSION, ctx.settings.moduleVersion)
                    .withMember(SwiftSettings.SDK_ID, ctx.settings.sdkId)
                    .withMember(SwiftSettings.INTERNAL_CLIENT, ctx.settings.internalClient)
                    .withMember(SwiftSettings.OPERATIONS, ArrayNode.fromStrings(ctx.settings.operations))
                    .withMember(SwiftSettings.MODEL_PATH, ctx.settings.modelPath)
                    .build()
            writer.write(Node.prettyPrintJson(node))
        }
    }
}
