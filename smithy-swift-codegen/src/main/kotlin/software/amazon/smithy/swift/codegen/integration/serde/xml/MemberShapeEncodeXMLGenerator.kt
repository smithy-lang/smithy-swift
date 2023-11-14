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
import software.amazon.smithy.model.traits.XmlAttributeTrait
import software.amazon.smithy.model.traits.XmlFlattenedTrait
import software.amazon.smithy.model.traits.XmlNameTrait
import software.amazon.smithy.model.traits.XmlNamespaceTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeEncodeGeneratable
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait

abstract class MemberShapeEncodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
) : MemberShapeEncodeGeneratable {

    fun writeMember(memberShape: MemberShape, unionMember: Boolean) {
        val prefix = "value.".takeIf { !unionMember } ?: ""
        val targetShape = ctx.model.expectShape(memberShape.target)
        when (targetShape) {
            is StructureShape, is UnionShape -> {
                writeStructureOrUnionMember(memberShape, targetShape, prefix)
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

    private fun writeStructureOrUnionMember(memberShape: MemberShape, targetShape: Shape, prefix: String) {
        val memberName = ctx.symbolProvider.toMemberName(memberShape)
        val targetSymbol = ctx.symbolProvider.toSymbol(targetShape)
        val propertyKey = nodeInfo(memberShape)
        writer.write(
            "try \$N.writingClosure(\$L\$L, to: writer[\$L])",
            targetSymbol,
            prefix,
            memberName,
            propertyKey
        )
    }

    private fun writeTimestampMember(memberShape: MemberShape, timestampShape: TimestampShape, prefix: String) {
        val memberName = ctx.symbolProvider.toMemberName(memberShape)
        val timestampKey = nodeInfo(memberShape)
        val swiftTimestampFormatCase = timestampFormat(memberShape, timestampShape)
        writer.write(
            "try writer[\$L].writeTimestamp(\$L\$L, format: \$L)",
            timestampKey,
            prefix,
            memberName,
            swiftTimestampFormatCase
        )
    }

    private fun timestampFormat(memberShape: MemberShape, timestampShape: TimestampShape): String {
        val timestampFormatTrait = memberShape.getTrait<TimestampFormatTrait>() ?: timestampShape.getTrait<TimestampFormatTrait>() ?: TimestampFormatTrait(TimestampFormatTrait.DATE_TIME)
        return when (timestampFormatTrait.value) {
            TimestampFormatTrait.EPOCH_SECONDS -> ".epochSeconds"
            TimestampFormatTrait.HTTP_DATE -> ".httpDate"
            else -> ".dateTime"
        }
    }

    private fun writePropertyMember(memberShape: MemberShape, targetShape: Shape, prefix: String) {
        val memberName = ctx.symbolProvider.toMemberName(memberShape)
        val propertyNodeInfo = nodeInfo(memberShape)
        writer.write(
            "try writer[\$L].write(\$L\$L)",
            propertyNodeInfo,
            prefix,
            memberName
        )
    }

    private fun writeListMember(member: MemberShape, listShape: ListShape, prefix: String) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val listMemberWriter = valueWriter(listShape.member)
        val listKey = nodeInfo(member)
        val isFlattened = member.hasTrait<XmlFlattenedTrait>()
        val memberNodeInfo = nodeInfo(listShape.member)
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
        val mapKey = nodeInfo(member)
        val keyNodeInfo = nodeInfo(mapShape.key)
        val valueNodeInfo = nodeInfo(mapShape.value)
        val valueWriter = valueWriter(mapShape.value)
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

    private fun valueWriter(member: MemberShape): String {
        val target = ctx.model.expectShape(member.target)
        when (target) {
            is MapShape -> {
                val keyNodeInfo = nodeInfo(target.key)
                val valueNodeInfo = nodeInfo(target.value)
                val valueWriter = valueWriter(target.value)
                val isFlattened = target.hasTrait<XmlFlattenedTrait>()
                return writer.format(
                    "SmithyXML.mapWritingClosure(valueWritingClosure: \$L, keyNodeInfo: \$L, valueNodeInfo: \$L, isFlattened: \$L)",
                    valueWriter,
                    keyNodeInfo,
                    valueNodeInfo,
                    isFlattened
                )
            }
            is ListShape -> {
                val memberNodeInfo = nodeInfo(target.member)
                val memberWriter = valueWriter(target.member)
                val isFlattened = target.hasTrait<XmlFlattenedTrait>()
                return writer.format(
                    "SmithyXML.listWritingClosure(memberWritingClosure: \$L, memberNodeInfo: \$L, isFlattened: \$L)",
                    memberWriter,
                    memberNodeInfo,
                    isFlattened
                )
            }
            is TimestampShape -> {
                val memberNodeInfo = nodeInfo(member)
                return writer.format(
                    "SmithyXML.timestampWritingClosure(memberNodeInfo: \$L, format: \$L)",
                    memberNodeInfo,
                    timestampFormat(member, target)
                )
            }
            else -> {
                return writer.format("\$N.writingClosure(_:to:)", ctx.symbolProvider.toSymbol(target))
            }
        }
    }

    fun nodeInfo(structure: StructureShape): String {
        val xmlNameTrait = structure.getTrait<XmlNameTrait>()
        val structureSymbol = ctx.symbolProvider.toSymbol(structure)
        val resolvedName = xmlNameTrait?.let { it.value } ?: structureSymbol.name

        val xmlNamespaceTrait = structure.getTrait<XmlNamespaceTrait>() ?: ctx.service.getTrait<XmlNamespaceTrait>()
        val xmlNamespaceParam = xmlNamespaceTrait?.let { namespace(it) } ?: ""

        return writer.format(
            ".init(\$S\$L)",
            resolvedName,
            xmlNamespaceParam
        )
    }

    private fun nodeInfo(member: MemberShape): String {
        val xmlNameTrait = member.getTrait<XmlNameTrait>()
        val resolvedName = xmlNameTrait?.let { it.value } ?: member.memberName

        val xmlAttributeParam = ", location: .attribute".takeIf { member.hasTrait<XmlAttributeTrait>() } ?: ""

        val xmlNamespaceTrait = member.getTrait<XmlNamespaceTrait>()
        val xmlNamespaceParam = xmlNamespaceTrait?.let { namespace(it) } ?: ""

        return writer.format(
            ".init(\$S\$L\$L)",
            resolvedName,
            xmlAttributeParam,
            xmlNamespaceParam
        )
    }

    private fun namespace(xmlNamespaceTrait: XmlNamespaceTrait): String {
        return writer.format(
            ", namespace: .init(prefix: \$S, uri: \$S)",
            xmlNamespaceTrait.prefix,
            xmlNamespaceTrait.uri
        )
    }
}
