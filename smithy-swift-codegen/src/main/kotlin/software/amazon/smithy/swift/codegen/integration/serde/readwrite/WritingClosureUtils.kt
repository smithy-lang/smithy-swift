package software.amazon.smithy.swift.codegen.integration.serde.readwrite

import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.XmlFlattenedTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.json.TimestampUtils
import software.amazon.smithy.swift.codegen.integration.serde.xml.NodeInfoUtils
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait

class WritingClosureUtils(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter
) {

    private val nodeInfoUtils = NodeInfoUtils(ctx, writer)

    fun writingClosure(member: MemberShape): String {
        val target = ctx.model.expectShape(member.target)
        val memberTimestampFormatTrait = member.getTrait<TimestampFormatTrait>()
        return writingClosure(target, memberTimestampFormatTrait)
    }

    fun writingClosure(shape: Shape): String {
        return writingClosure(shape, null)
    }

    private fun writingClosure(shape: Shape, memberTimestampFormatTrait: TimestampFormatTrait? = null): String {
        when (ctx.service.requestWireProtocol) {
            WireProtocol.JSON -> return "JSONReadWrite.writingClosure()"
            WireProtocol.FORM_URL -> return "FormURLReadWrite.writingClosure()"
        }
        return when (shape) {
            is MapShape -> {
                val keyNodeInfo = nodeInfoUtils.nodeInfo(shape.key)
                val valueNodeInfo = nodeInfoUtils.nodeInfo(shape.value)
                val valueWriter = writingClosure(shape.value)
                val isFlattened = shape.hasTrait<XmlFlattenedTrait>()
                writer.format(
                    "SmithyXML.mapWritingClosure(valueWritingClosure: \$L, keyNodeInfo: \$L, valueNodeInfo: \$L, isFlattened: \$L)",
                    valueWriter,
                    keyNodeInfo,
                    valueNodeInfo,
                    isFlattened
                )
            }
            is ListShape -> {
                val memberNodeInfo = nodeInfoUtils.nodeInfo(shape.member)
                val memberWriter = writingClosure(shape.member)
                val isFlattened = shape.hasTrait<XmlFlattenedTrait>()
                writer.format(
                    "SmithyXML.listWritingClosure(memberWritingClosure: \$L, memberNodeInfo: \$L, isFlattened: \$L)",
                    memberWriter,
                    memberNodeInfo,
                    isFlattened
                )
            }
            is TimestampShape -> {
                writer.format(
                    "SmithyXML.timestampWritingClosure(format: \$L)",
                    TimestampUtils.timestampFormat(memberTimestampFormatTrait, shape)
                )
            }
            else -> {
                writer.format("\$N.writingClosure(_:to:)", ctx.symbolProvider.toSymbol(shape))
            }
        }
    }
}
