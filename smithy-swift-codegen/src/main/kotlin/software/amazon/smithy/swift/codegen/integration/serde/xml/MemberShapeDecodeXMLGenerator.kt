/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.model.shapes.BigDecimalShape
import software.amazon.smithy.model.shapes.BigIntegerShape
import software.amazon.smithy.model.shapes.BooleanShape
import software.amazon.smithy.model.shapes.ByteShape
import software.amazon.smithy.model.shapes.DoubleShape
import software.amazon.smithy.model.shapes.EnumShape
import software.amazon.smithy.model.shapes.FloatShape
import software.amazon.smithy.model.shapes.IntEnumShape
import software.amazon.smithy.model.shapes.IntegerShape
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.LongShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.SetShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShortShape
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.DefaultTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.XmlFlattenedTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.json.TimestampUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.ReadingClosureUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.responseWireProtocol
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.isError
import software.amazon.smithy.swift.codegen.swiftEnumCaseName

class MemberShapeDecodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val shapeContainingMembers: Shape,
) {
    private val nodeInfoUtils = NodeInfoUtils(ctx, writer, ctx.service.responseWireProtocol)
    private val readingClosureUtils = ReadingClosureUtils(ctx, writer)

    fun render(member: MemberShape, isPayload: Boolean = false) {
        val targetShape = ctx.model.expectShape(member.target)
        val readExp = when (targetShape) {
            is StructureShape, is UnionShape -> renderStructOrUnionExp(member, isPayload)
            is MapShape -> renderMapExp(member, targetShape)
            is ListShape -> renderListExp(member, targetShape)
            is TimestampShape -> renderTimestampExp(member, targetShape)
            else -> renderMemberExp(member, isPayload)
        }
        val memberName = ctx.symbolProvider.toMemberName(member)
        if (shapeContainingMembers.isUnionShape) {
            writer.write("return .\$L(\$L)", memberName, readExp)
        } else if (shapeContainingMembers.isError) {
            writer.write("value.properties.\$L = \$L", memberName, readExp)
        } else {
            writer.write("value.\$L = \$L", memberName, readExp)
        }
    }

    private fun renderStructOrUnionExp(memberShape: MemberShape, isPayload: Boolean): String {
        val readingClosure = readingClosureUtils.readingClosure(memberShape)
        return writer.format(
            "try \$L.\$L(readingClosure: \$L)",
            reader(memberShape, isPayload),
            readMethodName("read"),
            readingClosure
        )
    }

    private fun renderListExp(memberShape: MemberShape, listShape: ListShape): String {
        val memberReadingClosure = readingClosureUtils.readingClosure(listShape.member)
        val memberNodeInfo = nodeInfoUtils.nodeInfo(listShape.member)
        val isFlattened = memberShape.hasTrait<XmlFlattenedTrait>()
        return writer.format(
            "try \$L.\$L(memberReadingClosure: \$L, memberNodeInfo: \$L, isFlattened: \$L)",
            reader(memberShape, false),
            readMethodName("readList"),
            memberReadingClosure,
            memberNodeInfo,
            isFlattened
        )
    }

    private fun renderMapExp(memberShape: MemberShape, mapShape: MapShape): String {
        val valueReadingClosure = ReadingClosureUtils(ctx, writer).readingClosure(mapShape.value)
        val keyNodeInfo = nodeInfoUtils.nodeInfo(mapShape.key)
        val valueNodeInfo = nodeInfoUtils.nodeInfo(mapShape.value)
        val isFlattened = memberShape.hasTrait<XmlFlattenedTrait>()
        return writer.format(
            "try \$L.\$L(valueReadingClosure: \$L, keyNodeInfo: \$L, valueNodeInfo: \$L, isFlattened: \$L)",
            reader(memberShape, false),
            readMethodName("readMap"),
            valueReadingClosure,
            keyNodeInfo,
            valueNodeInfo,
            isFlattened
        )
    }

    private fun renderTimestampExp(memberShape: MemberShape, timestampShape: TimestampShape): String {
        val memberTimestampFormatTrait = memberShape.getTrait<TimestampFormatTrait>()
        val swiftTimestampFormatCase = TimestampUtils.timestampFormat(memberTimestampFormatTrait, timestampShape)
        return writer.format(
            "try \$L.\$L(format: \$L)",
            reader(memberShape, false),
            readMethodName("readTimestamp"),
            swiftTimestampFormatCase
        )
    }

    private fun renderMemberExp(memberShape: MemberShape, isPayload: Boolean): String {
        return writer.format(
            "try \$L.\$L()\$L",
            reader(memberShape, isPayload),
            readMethodName("read"),
            default(memberShape),
        )
    }

    private fun readMethodName(baseName: String): String {
        return "${baseName}${"".takeIf { shapeContainingMembers.isUnionShape } ?: "IfPresent"}"
    }

    private fun reader(memberShape: MemberShape, isPayload: Boolean): String {
        val nodeInfo = nodeInfoUtils.nodeInfo(memberShape)
        return "reader".takeIf { isPayload } ?: writer.format("reader[\$L]", nodeInfo)
    }

    private fun default(memberShape: MemberShape): String {
        val targetShape = ctx.model.expectShape(memberShape.target)
        val defaultTrait = memberShape.getTrait<DefaultTrait>() ?: targetShape.getTrait<DefaultTrait>()
        return defaultTrait?.toNode()?.let {
            // If the default value is null, provide no default.
            if (it.isNullNode) { return "" }
            // Provide a default value dependent on the type.
            return when (targetShape) {
                is EnumShape -> " ?? .${swiftEnumCaseName(it.expectStringNode().value, "")}"
                is IntEnumShape -> " ?? .${swiftEnumCaseName(it.expectStringNode().value, "")}"
                is StringShape -> " ?? \"${it.expectStringNode().value}\""
                is ByteShape -> " ?? ${it.expectNumberNode().value}"
                is ShortShape -> " ?? ${it.expectNumberNode().value}"
                is IntegerShape -> " ?? ${it.expectNumberNode().value}"
                is LongShape -> " ?? ${it.expectNumberNode().value}"
                is FloatShape -> " ?? ${it.expectNumberNode().value}"
                is DoubleShape -> " ?? ${it.expectNumberNode().value}"
                is BigIntegerShape -> " ?? ${it.expectNumberNode().value}"
                is BigDecimalShape -> " ?? ${it.expectNumberNode().value}"
                is BooleanShape -> " ?? ${it.expectBooleanNode().value}"
                // Lists can only have empty list as default value
                is ListShape, is SetShape -> " ?? []"
                // Maps can only have empty map as default value
                is MapShape -> " ?? [:]"
                // No default provided for other shapes
                else -> ""
            }
        } ?: "" // If there is no default trait, provide no default value.
    }
}
