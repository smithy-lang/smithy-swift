/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration.serde.json

import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.XmlFlattenedTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeEncodeGeneratable
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.WritingClosureUtils
import software.amazon.smithy.swift.codegen.integration.serde.xml.NodeInfoUtils
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait

abstract class MemberShapeEncodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
) : MemberShapeEncodeGeneratable {

    private val writingClosureUtils = WritingClosureUtils(ctx, writer)

    private val nodeInfoUtils = NodeInfoUtils(ctx, writer)

    fun writeMember(memberShape: MemberShape, unionMember: Boolean) {
        val prefix = "value.".takeIf { !unionMember } ?: ""
        val targetShape = ctx.model.expectShape(memberShape.target)
        when (targetShape) {
            is StructureShape, is UnionShape -> {
                writeStructureOrUnionMember(memberShape, prefix)
            }
            is ListShape -> {
                writeListMember(memberShape, targetShape, prefix)
            }
            is MapShape -> {
                writeMapMember(memberShape, targetShape, prefix)
            }
            is TimestampShape -> {
                writeTimestampMember(memberShape, targetShape, prefix)
            }
            else -> {
                writePropertyMember(memberShape, targetShape, prefix)
            }
        }
    }

    private fun writeStructureOrUnionMember(memberShape: MemberShape, prefix: String) {
        val memberName = ctx.symbolProvider.toMemberName(memberShape)
        val propertyKey = nodeInfoUtils.nodeInfo(memberShape)
        val writingClosure = writingClosureUtils.writingClosure(memberShape)
        writer.write(
            "try writer[\$L].write(\$L\$L, writingClosure: \$L)",
            propertyKey,
            prefix,
            memberName,
            writingClosure
        )
    }

    private fun writeTimestampMember(memberShape: MemberShape, timestampShape: TimestampShape, prefix: String) {
        val memberName = ctx.symbolProvider.toMemberName(memberShape)
        val timestampKey = nodeInfoUtils.nodeInfo(memberShape)
        val memberTimestampFormatTrait = memberShape.getTrait<TimestampFormatTrait>()
        val swiftTimestampFormatCase = TimestampUtils.timestampFormat(memberTimestampFormatTrait, timestampShape)
        writer.write(
            "try writer[\$L].writeTimestamp(\$L\$L, format: \$L)",
            timestampKey,
            prefix,
            memberName,
            swiftTimestampFormatCase
        )
    }

    private fun writePropertyMember(memberShape: MemberShape, targetShape: Shape, prefix: String) {
        val memberName = ctx.symbolProvider.toMemberName(memberShape)
        val propertyNodeInfo = nodeInfoUtils.nodeInfo(memberShape)
        writer.write(
            "try writer[\$L].write(\$L\$L)",
            propertyNodeInfo,
            prefix,
            memberName
        )
    }

    private fun writeListMember(member: MemberShape, listShape: ListShape, prefix: String) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val listMemberWriter = writingClosureUtils.writingClosure(listShape.member)
        val listKey = nodeInfoUtils.nodeInfo(member)
        val isFlattened = member.hasTrait<XmlFlattenedTrait>()
        val memberNodeInfo = nodeInfoUtils.nodeInfo(listShape.member)
        writer.write(
            "try writer[\$L].writeList(\$L\$L, memberWritingClosure: \$L, memberNodeInfo: \$L, isFlattened: \$L)",
            listKey,
            prefix,
            memberName,
            listMemberWriter,
            memberNodeInfo,
            isFlattened
        )
    }

    private fun writeMapMember(member: MemberShape, mapShape: MapShape, prefix: String) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val mapKey = nodeInfoUtils.nodeInfo(member)
        val keyNodeInfo = nodeInfoUtils.nodeInfo(mapShape.key)
        val valueNodeInfo = nodeInfoUtils.nodeInfo(mapShape.value)
        val valueWriter = writingClosureUtils.writingClosure(mapShape.value)
        val isFlattened = member.hasTrait<XmlFlattenedTrait>()
        writer.write(
            "try writer[\$L].writeMap(\$L\$L, valueWritingClosure: \$L, keyNodeInfo: \$L, valueNodeInfo: \$L, isFlattened: \$L)",
            mapKey,
            prefix,
            memberName,
            valueWriter,
            keyNodeInfo,
            valueNodeInfo,
            isFlattened
        )
    }
}

object TimestampUtils {

    fun timestampFormat(memberTimestampFormatTrait: TimestampFormatTrait?, timestampShape: TimestampShape): String {
        val timestampFormatTrait = memberTimestampFormatTrait ?: timestampShape.getTrait<TimestampFormatTrait>() ?: TimestampFormatTrait(TimestampFormatTrait.DATE_TIME)
        return when (timestampFormatTrait.value) {
            TimestampFormatTrait.EPOCH_SECONDS -> ".epochSeconds"
            TimestampFormatTrait.HTTP_DATE -> ".httpDate"
            else -> ".dateTime"
        }
    }
}
