package software.amazon.smithy.swift.codegen.integration.serde.readwrite

import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.SparseTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.XmlFlattenedTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.json.TimestampUtils
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait

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
        val base = when (shape) {
            is MapShape -> {
                val keyNodeInfo = nodeInfoUtils.nodeInfo(shape.key)
                val valueNodeInfo = nodeInfoUtils.nodeInfo(shape.value)
                val mapIsSparse = shape.hasTrait<SparseTrait>()
                val valueWriter = writingClosure(shape.value, mapIsSparse)
                val isFlattened = shape.hasTrait<XmlFlattenedTrait>()
                writer.format(
                    "mapWritingClosure(valueWritingClosure: \$L, keyNodeInfo: \$L, valueNodeInfo: \$L, isFlattened: \$L)",
                    valueWriter,
                    keyNodeInfo,
                    valueNodeInfo,
                    isFlattened
                )
            }
            is ListShape -> {
                val memberNodeInfo = nodeInfoUtils.nodeInfo(shape.member)
                val listIsSparse = shape.hasTrait<SparseTrait>()
                val memberWriter = writingClosure(shape.member, listIsSparse)
                val isFlattened = shape.hasTrait<XmlFlattenedTrait>()
                writer.format(
                    "listWritingClosure(memberWritingClosure: \$L, memberNodeInfo: \$L, isFlattened: \$L)",
                    memberWriter,
                    memberNodeInfo,
                    isFlattened
                )
            }
            is TimestampShape -> {
                writer.format(
                    "timestampWritingClosure(format: \$L)",
                    TimestampUtils.timestampFormat(ctx, memberTimestampFormatTrait, shape)
                )
            }
            else -> {
                writer.format("\$N.write(value:to:)", ctx.symbolProvider.toSymbol(shape))
            }
        }
        return if (isSparse) {
            writer.format("sparseFormOf(writingClosure: \$L)", base)
        } else {
            base
        }
    }
}
