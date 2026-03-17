package software.amazon.smithy.swift.codegen

import software.amazon.smithy.model.node.ArrayNode
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.node.ObjectNode
import software.amazon.smithy.model.node.StringNode
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import java.util.Optional

class SwiftSettingsJSONGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
) {
    fun render() {
        val path = "Sources/${ctx.settings.moduleName}/swift-settings.json"
        ctx.delegator.useFileWriter(path) { writer ->
            val node =
                ObjectNode
                    .builder()
                    .withMember(SwiftSettings.SERVICE, ctx.settings.service.toString())
                    .withMember(SwiftSettings.MODULE_NAME, ctx.settings.moduleName)
                    .withMember(SwiftSettings.SDK_ID, ctx.settings.sdkId)
                    .withMember(SwiftSettings.INTERNAL_CLIENT, ctx.settings.internalClient)
                    .withMember(SwiftSettings.OPERATIONS, ArrayNode.fromStrings(ctx.settings.operations))
                    .withOptionalMember(
                        SwiftSettings.MODEL_PATH,
                        ctx.settings.modelPath?.let {
                            Optional.of(StringNode.from(it))
                        } ?: Optional.empty(),
                    ).build()
            writer.write(Node.prettyPrintJson(node))
        }
    }
}
