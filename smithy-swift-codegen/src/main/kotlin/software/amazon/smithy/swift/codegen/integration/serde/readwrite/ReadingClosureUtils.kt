package software.amazon.smithy.swift.codegen.integration.serde.readwrite

import software.amazon.smithy.model.shapes.EnumShape
import software.amazon.smithy.model.shapes.IntEnumShape
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.XmlFlattenedTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.json.TimestampUtils
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyReadWriteTypes

class ReadingClosureUtils(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter
) {
    private val nodeInfoUtils = NodeInfoUtils(ctx, writer, ctx.service.responseWireProtocol)

    fun readingClosure(member: MemberShape, isSparse: Boolean = false): String {
        val target = ctx.model.expectShape(member.target)
        val memberTimestampFormatTrait = member.getTrait<TimestampFormatTrait>()
        return makeReadingClosure(target, memberTimestampFormatTrait, isSparse)
    }

    private fun makeReadingClosure(shape: Shape, memberTimestampFormatTrait: TimestampFormatTrait? = null, isSparse: Boolean): String {
        val base = when {
            shape is MapShape -> {
                val valueReadingClosure = readingClosure(shape.value)
                val keyNodeInfo = nodeInfoUtils.nodeInfo(shape.key)
                val valueNodeInfo = nodeInfoUtils.nodeInfo(shape.value)
                val isFlattened = shape.hasTrait<XmlFlattenedTrait>()
                writer.format(
                    "\$N(valueReadingClosure: \$L, keyNodeInfo: \$L, valueNodeInfo: \$L, isFlattened: \$L)",
                    SmithyReadWriteTypes.mapReadingClosure,
                    valueReadingClosure,
                    keyNodeInfo,
                    valueNodeInfo,
                    isFlattened
                )
            }
            shape is ListShape -> {
                val memberReadingClosure = readingClosure(shape.member)
                val memberNodeInfo = nodeInfoUtils.nodeInfo(shape.member)
                val isFlattened = shape.hasTrait<XmlFlattenedTrait>()
                writer.format(
                    "\$N(memberReadingClosure: \$L, memberNodeInfo: \$L, isFlattened: \$L)",
                    SmithyReadWriteTypes.listReadingClosure,
                    memberReadingClosure,
                    memberNodeInfo,
                    isFlattened
                )
            }
            shape is TimestampShape -> {
                writer.format(
                    "\$N(format: \$L)",
                    SmithyReadWriteTypes.timestampReadingClosure,
                    TimestampUtils.timestampFormat(ctx, memberTimestampFormatTrait, shape)
                )
            }
            shape is EnumShape || shape is IntEnumShape || shape.hasTrait<EnumTrait>() -> {
                writer.format(
                    "\$N<\$N>().read(from:)",
                    SmithyReadWriteTypes.ReadingClosureBox,
                    ctx.symbolProvider.toSymbol(shape),
                )
            }
            shape is MemberShape -> {
                readingClosure(shape, isSparse)
            }
            shape is StructureShape || shape is UnionShape -> {
                writer.format("\$N.read(from:)", ctx.symbolProvider.toSymbol(shape))
            }
            else -> {
//                println("${shape.id} is a ${shape.javaClass.simpleName}")
                writer.format("\$N.read\$L(from:)",
                    SmithyReadWriteTypes.ReadingClosures,
                    ctx.symbolProvider.toSymbol(shape).name,
                )
            }
        }
        if (isSparse) {
            return writer.format("\$N(readingClosure: \$L)", SmithyReadWriteTypes.optionalFormOf, base)
        } else {
            return base
        }
    }
}
