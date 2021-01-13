/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.neighbor.RelationshipType
import software.amazon.smithy.model.neighbor.Walker
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.SetShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftBoxTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.defaultName
import software.amazon.smithy.swift.codegen.isBoxed
import software.amazon.smithy.swift.codegen.recursiveSymbol

/*
Includes functions to help render conformance to Decodable protocol for shapes
 */
open class MemberShapeDecodeGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) {
    fun renderDecodeForTimestamp(ctx: ProtocolGenerator.GenerationContext, target: Shape, member: MemberShape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val tsFormat = member
            .getTrait(TimestampFormatTrait::class.java)
            .map { it.format }
            .orElse(defaultTimestampFormat)
        if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) {
            writeDecodeForPrimitive(target, member, containerName)
        } else {
            val dateSymbol = "String"
            val originalSymbol = ctx.symbolProvider.toSymbol(target)
            val dateString = "${memberName}DateString"
            val decodedMemberName = "${memberName}Decoded"
            writer.write("let \$L = try $containerName.decodeIfPresent(\$L.self, forKey: .\$L)", dateString, dateSymbol, memberName)
            writer.write("var \$L: \$T = nil", decodedMemberName, originalSymbol)
            writer.openBlock("if let \$L = \$L {", "}", dateString, dateString) {
                val formatterName = "${memberName}Formatter"
                writeDateFormatter(formatterName, tsFormat, writer)
                writer.write("\$L = \$L.date(from: \$L)", decodedMemberName, formatterName, dateString)
            }
            renderAssigningDecodedMember(member, decodedMemberName)
        }
    }

    fun writeDecodeForPrimitive(shape: Shape, member: MemberShape, containerName: String) {
        var symbol = ctx.symbolProvider.toSymbol(shape)
        val memberName = ctx.symbolProvider.toMemberName(member).removeSurrounding("`", "`")
        if (member.hasTrait(SwiftBoxTrait::class.java)) {
            symbol = symbol.recursiveSymbol()
        }
        val decodeVerb = if (symbol.isBoxed()) "decodeIfPresent" else "decode"
        val decodedMemberName = "${memberName}Decoded"
        writer.write("let \$L = try \$L.$decodeVerb(\$L.self, forKey: .\$L)", decodedMemberName, containerName, symbol.name, memberName)
        renderAssigningDecodedMember(member, decodedMemberName)
    }

    // TODO remove this when we switch to a custom date type as this wont be necessary anymore
    private fun getSymbolName(shape: Shape): String {
        val symbol = ctx.symbolProvider.toSymbol(shape)
        val walker = Walker(ctx.model)
        if (symbol.name.contains("Date")) {
            // if symbol name contains the Date symbol, check timestamp format. if the timestamp format is not epoch seconds,
            // change Date to String to properly decode
            val walkedShapes = walker.iterateShapes(shape) { relationship ->
                when (relationship.relationshipType) {
                    RelationshipType.MEMBER_TARGET,
                    RelationshipType.STRUCTURE_MEMBER,
                    RelationshipType.LIST_MEMBER,
                    RelationshipType.SET_MEMBER,
                    RelationshipType.MAP_VALUE,
                    RelationshipType.UNION_MEMBER -> true
                    else -> false
                }
            }
            loop@ for (walkedShape in walkedShapes) {
                return if (walkedShape.type == ShapeType.TIMESTAMP) {
                    val tsFormat = walkedShape
                        .getTrait(TimestampFormatTrait::class.java)
                        .map { it.format }
                        .orElse(defaultTimestampFormat)
                    if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) {
                        symbol.name
                    } else {
                        symbol.name.replace("Date", "String")
                    }
                } else {
                    continue@loop
                }
            }
        }
        return symbol.name
    }

    private fun writeDateFormatter(formatterName: String, tsFormat: TimestampFormatTrait.Format, writer: SwiftWriter) {
        when (tsFormat) {
            TimestampFormatTrait.Format.EPOCH_SECONDS -> writer.write("let \$L = DateFormatter()", formatterName)
            // FIXME return to this to figure out when to use fractional seconds precision in more general sense after we switch
            // to custom date type
            TimestampFormatTrait.Format.DATE_TIME -> writer.write("let \$L = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds", formatterName)
            TimestampFormatTrait.Format.HTTP_DATE -> writer.write("let \$L = DateFormatter.rfc5322DateFormatter", formatterName)
            else -> throw CodegenException("unknown timestamp format: $tsFormat")
        }
    }

    private fun renderDecodingDateError(member: MemberShape) {
        val memberName = member.memberName
        writer.write("throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: values.codingPath + [CodingKeys.$memberName], debugDescription: \"date cannot be properly deserialized\"))")
    }

    fun renderDecodeListMember(
        shape: CollectionShape,
        memberName: String,
        containerName: String,
        topLevelMember: MemberShape,
        level: Int = 0
    ) {
        val symbolName = getSymbolName(shape)
        val originalSymbol = ctx.symbolProvider.toSymbol(shape)
        val decodedMemberName = "${memberName.removeSurrounding("`", "`")}Decoded$level"
        val insertMethod = when (ctx.model.expectShape(topLevelMember.target)) {
            is SetShape -> "insert"
            is ListShape -> "append"
            else -> "append"
        }
        val nestedTarget = ctx.model.expectShape(shape.member.target)
        if (level == 0) {
            val listContainerName = "${memberName}Container"
            val decodeVerb = if (originalSymbol.isBoxed()) "decodeIfPresent" else "decode"
            writer.write(
                "let \$L = try values.$decodeVerb(\$L.self, forKey: .\$L)",
                listContainerName,
                symbolName,
                memberName
            )
            writer.write("var \$L:\$T = nil", decodedMemberName, originalSymbol)
            writer.openBlock("if let \$L = \$L {", "}", listContainerName, listContainerName) {
                writer.write("\$L = \$L()", decodedMemberName, originalSymbol)
                renderDecodeListTarget(nestedTarget, decodedMemberName, listContainerName, insertMethod, topLevelMember, level)
            }
            renderAssigningDecodedMember(topLevelMember, decodedMemberName)
        } else {
            val isBoxed = ctx.symbolProvider.toSymbol(nestedTarget).isBoxed()
            if (isBoxed) {
                writer.openBlock("if let \$L = \$L {", "}", memberName, memberName) {
                    renderDecodeListTarget(nestedTarget, containerName, memberName, insertMethod, topLevelMember, level)
                }
            } else {
                renderDecodeListTarget(nestedTarget, containerName, memberName, insertMethod, topLevelMember, level)
            }
        }
    }

    /*
    Simple assignment of the decode value to the member.
    Can be overridden to allow post processing of the decoded value before assigning it to the member.
     */
    open fun renderAssigningDecodedMember(topLevelMember: MemberShape, decodedMemberName: String) {
        val topLevelMemberName = ctx.symbolProvider.toMemberName(topLevelMember).removeSurrounding("`", "`")
        writer.write("\$L = \$L", topLevelMemberName, decodedMemberName)
    }

    private fun renderDecodeListTarget(shape: Shape, decodedMemberName: String, collectionName: String, insertMethod: String, topLevelMember: MemberShape, level: Int = 0) {
        val iteratorName = "${shape.type.name.toLowerCase()}$level"
        val originalSymbol = ctx.symbolProvider.toSymbol(shape)
        val terminator = if (level == 0) "?" else ""
        writer.openBlock("for $iteratorName in $collectionName {", "}") {
            when (shape) {
                is TimestampShape -> {
                    val tsFormat = shape
                        .getTrait(TimestampFormatTrait::class.java)
                        .map { it.format }
                        .orElse(defaultTimestampFormat)

                    if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) { // if decoding a double decode as normal from [[Date]].self
                        writer.write("${decodedMemberName}$terminator.$insertMethod($iteratorName)")
                    } else { // decode date as a string manually
                        val formatterName = "${iteratorName}Formatter"
                        writeDateFormatter(formatterName, tsFormat, writer)
                        val dateName = "date$level"
                        writer.openBlock("guard let $dateName = $formatterName.date(from: $iteratorName) else {", "}") {
                            renderDecodingDateError(topLevelMember)
                        }
                        writer.write("${decodedMemberName}$terminator.$insertMethod($dateName)")
                    }
                }
                is CollectionShape -> {
                    val nestedDecodedMemberName = "${iteratorName}Decoded$level"
                    writer.write("var \$L = \$L()", nestedDecodedMemberName, originalSymbol)
                    renderDecodeListMember(shape, iteratorName, nestedDecodedMemberName, topLevelMember, level + 1)
                    writer.write("$decodedMemberName?.$insertMethod($nestedDecodedMemberName)")
                }
                is MapShape -> {
                    val nestedDecodedMemberName = "${collectionName}Decoded$level"
                    writer.write("var \$L = \$L()", nestedDecodedMemberName, originalSymbol)
                    renderDecodeMapMember(shape, iteratorName, nestedDecodedMemberName, topLevelMember, level + 1)
                    writer.write("$decodedMemberName?.$insertMethod($nestedDecodedMemberName)")
                }
                else -> writer.write("${decodedMemberName}$terminator.$insertMethod($iteratorName)")
            }
        }
    }

    fun renderDecodeMapMember(
        shape: MapShape,
        memberName: String,
        containerName: String,
        topLevelMember: MemberShape,
        level: Int = 0
    ) {
        val symbolName = getSymbolName(shape)
        val originalSymbol = ctx.symbolProvider.toSymbol(shape)
        val decodedMemberName = "${memberName}Decoded$level"
        val nestedTarget = ctx.model.expectShape(shape.value.target)
        if (level == 0) {
            val topLevelContainerName = "${memberName}Container"
            val decodeVerb = if (originalSymbol.isBoxed()) "decodeIfPresent" else "decode"
            writer.write("let \$L = try values.$decodeVerb(\$L.self, forKey: .\$L)",
                topLevelContainerName,
                symbolName,
                memberName)
            writer.write("var \$L: \$T = nil", decodedMemberName, originalSymbol)
            writer.openBlock("if let \$L = \$L {", "}", topLevelContainerName, topLevelContainerName) {
                writer.write("\$L = \$L()", decodedMemberName, originalSymbol)
                renderDecodeMapTarget(topLevelContainerName, decodedMemberName, nestedTarget, topLevelMember, level)
            }
            renderAssigningDecodedMember(topLevelMember, decodedMemberName)
        } else {
            renderDecodeMapTarget(memberName, containerName, nestedTarget, topLevelMember, level)
        }
    }

    private fun renderDecodeMapTarget(
        mapName: String,
        decodedMemberName: String,
        valueTargetShape: Shape,
        topLevelMember: MemberShape,
        level: Int = 0
    ) {
        val valueIterator = "${valueTargetShape.defaultName().toLowerCase()}$level"
        val originalSymbol = ctx.symbolProvider.toSymbol(valueTargetShape)
        val terminator = if (level == 0) "?" else ""
        writer.openBlock("for (key$level, $valueIterator) in $mapName {", "}") {
            when (valueTargetShape) {
                is CollectionShape -> {
                    val originalSymbol = ctx.symbolProvider.toSymbol(valueTargetShape)
                    val nestedDecodedMemberName = "${valueIterator}Decoded$level"
                    writer.write("var \$L = \$L()", nestedDecodedMemberName, originalSymbol)
                    renderDecodeListMember(valueTargetShape, valueIterator, nestedDecodedMemberName, topLevelMember, level + 1)
                    writer.write("$decodedMemberName?[key$level] = $nestedDecodedMemberName")
                }
                is MapShape -> {
                    val nestedDecodedMemberName = "${valueIterator}Decoded$level"
                    writer.write("var \$L = \$L()", nestedDecodedMemberName, originalSymbol)
                    renderDecodeMapMember(valueTargetShape, valueIterator, nestedDecodedMemberName, topLevelMember, level + 1)
                    writer.write("$decodedMemberName?[key$level] = $nestedDecodedMemberName")
                }
                is TimestampShape -> {
                    val tsFormat = valueTargetShape
                        .getTrait(TimestampFormatTrait::class.java)
                        .map { it.format }
                        .orElse(defaultTimestampFormat)

                    if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) { // if decoding a double decode as normal from [[Date]].self
                        writer.write("${decodedMemberName}$terminator[key$level] = $valueIterator")
                    } else { // decode date as a string manually
                        val formatterName = "${mapName}Formatter"
                        writeDateFormatter(formatterName, tsFormat, writer)
                        val dateName = "date$level"
                        writer.openBlock("guard let $dateName = $formatterName.date(from: $valueIterator) else {", "}") {
                            renderDecodingDateError(topLevelMember)
                        }
                        writer.write("${decodedMemberName}$terminator[key$level] = $dateName")
                    }
                }
                else -> writer.write("${decodedMemberName}$terminator[key$level] = $valueIterator")
            }
        }
    }
}
