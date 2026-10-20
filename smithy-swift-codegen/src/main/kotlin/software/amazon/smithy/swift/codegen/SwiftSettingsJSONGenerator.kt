package software.amazon.smithy.swift.codegen

import software.amazon.smithy.model.node.ArrayNode
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.node.ObjectNode
import software.amazon.smithy.model.node.StringNode
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.SerdeUtils
import software.amazon.smithy.swift.codegen.utils.SDKFileUtils
import java.util.Optional

class SwiftSettingsJSONGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
) {
    fun render() {
        if (!SerdeUtils.useSchemaBased(ctx)) return

        val filename = SDKFileUtils(ctx.settings).sourcesDirFilePath("swift-settings", "json")
        ctx.delegator.useFileWriter(filename) { writer ->
            val node = ObjectNode.builder().withMember(SwiftSettings.SERVICE, ctx.settings.service.toString())
            if (ctx.settings.internalClient) {
                node.withMember(SwiftSettings.INTERNAL_CLIENT, true)
            }
            if (ctx.settings.operations.isNotEmpty()) {
                node.withMember(SwiftSettings.OPERATIONS, ArrayNode.fromStrings(ctx.settings.operations))
            }
            node.withOptionalMember(
                SwiftSettings.MODEL_PATH,
                ctx.settings.modelPath.toOptionalStringNode(),
            )
            writer.write(Node.prettyPrintJson(node.build()))
        }
    }
}

private fun String?.toOptionalStringNode(): Optional<StringNode> = this?.let { Optional.of(StringNode.from(it)) } ?: Optional.empty()
