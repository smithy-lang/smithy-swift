package software.amazon.smithy.swift.codegen.integration.serde.readwrite

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.xml.NodeInfoUtils

class DocumentWritingClosureUtils(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter
) {
    fun closure(memberShape: MemberShape): String {
        val rootNodeInfo = NodeInfoUtils(ctx, writer, ctx.service.requestWireProtocol).nodeInfo(memberShape, true)
        return closure(rootNodeInfo)
    }

    fun closure(valueShape: Shape): String {
        val rootNodeInfo = NodeInfoUtils(ctx, writer, ctx.service.requestWireProtocol).nodeInfo(valueShape)
        return closure(rootNodeInfo)
    }
    private fun closure(rootNodeInfo: String): String {
        return writer.format("SmithyReadWrite.documentWritingClosure(rootNodeInfo: \$L)", rootNodeInfo)
    }
}
