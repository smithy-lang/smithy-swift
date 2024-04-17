package software.amazon.smithy.swift.codegen.integration.serde.readwrite

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class DocumentReadingClosureUtils(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter
) {
    val nodeInfoUtils = NodeInfoUtils(ctx, writer, ctx.service.responseWireProtocol)

    fun closure(memberShape: MemberShape): String {
        val rootNodeInfo = nodeInfoUtils.nodeInfo(memberShape, true)
        return closure(rootNodeInfo)
    }

    private fun closure(rootNodeInfo: String): String {
        when (ctx.service.responseWireProtocol) {
            WireProtocol.XML -> {
                return writer.format("SmithyReadWrite.documentReadingClosure(rootNodeInfo: \$L)", rootNodeInfo)
            }
            WireProtocol.FORM_URL, WireProtocol.JSON -> {
                return writer.format("SmithyReadWrite.documentReadingClosure(rootNodeInfo: \"\")")
            }
        }
    }
}
