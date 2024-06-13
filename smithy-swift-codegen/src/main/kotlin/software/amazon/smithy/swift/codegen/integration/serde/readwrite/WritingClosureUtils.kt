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
import software.amazon.smithy.model.traits.SparseTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.XmlFlattenedTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.json.TimestampUtils
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyReadWriteTypes

class WritingClosureUtils(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter
) {

    private val nodeInfoUtils = NodeInfoUtils(ctx, writer, ctx.service.requestWireProtocol)

    fun writingClosure(member: MemberShape, isSparse: Boolean): String {
        val target = ctx.model.expectShape(member.target)
        val memberTimestampFormatTrait = member.getTrait<TimestampFormatTrait>()
        return makeWritingClosure(target, memberTimestampFormatTrait, isSparse)
    }

    fun writingClosure(shape: Shape): String {
        return makeWritingClosure(shape, null, false)
    }

    private fun makeWritingClosure(shape: Shape, memberTimestampFormatTrait: TimestampFormatTrait?, isSparse: Boolean): String {
        val base = when {
            shape is MapShape -> {
                val keyNodeInfo = nodeInfoUtils.nodeInfo(shape.key)
                val valueNodeInfo = nodeInfoUtils.nodeInfo(shape.value)
                val mapIsSparse = shape.hasTrait<SparseTrait>()
                val valueWriter = writingClosure(shape.value, mapIsSparse)
                val isFlattened = shape.hasTrait<XmlFlattenedTrait>()
                writer.format(
                    "\$N(valueWritingClosure: \$L, keyNodeInfo: \$L, valueNodeInfo: \$L, isFlattened: \$L)",
                    SmithyReadWriteTypes.mapWritingClosure,
                    valueWriter,
                    keyNodeInfo,
                    valueNodeInfo,
                    isFlattened
                )
            }
            shape is ListShape -> {
                val memberNodeInfo = nodeInfoUtils.nodeInfo(shape.member)
                val listIsSparse = shape.hasTrait<SparseTrait>()
                val memberWriter = writingClosure(shape.member, listIsSparse)
                val isFlattened = shape.hasTrait<XmlFlattenedTrait>()
                writer.format(
                    "\$N(memberWritingClosure: \$L, memberNodeInfo: \$L, isFlattened: \$L)",
                    SmithyReadWriteTypes.listWritingClosure,
                    memberWriter,
                    memberNodeInfo,
                    isFlattened
                )
            }
            shape is TimestampShape -> {
                writer.format(
                    "\$N(format: \$L)",
                    SmithyReadWriteTypes.timestampWritingClosure,
                    TimestampUtils.timestampFormat(ctx, memberTimestampFormatTrait, shape)
                )
            }
            shape is EnumShape || shape is IntEnumShape || shape.hasTrait<EnumTrait>() -> {
                writer.format(
                    "\$N<\$N>().write(value:to:)",
                    SmithyReadWriteTypes.WritingClosureBox,
                    ctx.symbolProvider.toSymbol(shape),
                )
            }
            shape is MemberShape -> {
                return writingClosure(shape, isSparse)
            }
            shape is StructureShape || shape is UnionShape -> {
                writer.format("\$N.write(value:to:)", ctx.symbolProvider.toSymbol(shape))
            }
            else -> {
                writer.format(
                    "\$N.write\$L(value:to:)",
                    SmithyReadWriteTypes.WritingClosures,
                    ctx.symbolProvider.toSymbol(shape).name,
                )
            }
        }
        return if (isSparse) {
            writer.format("\$N(writingClosure: \$L)", SmithyReadWriteTypes.sparseFormOf, base)
        } else {
            base
        }
    }
}
