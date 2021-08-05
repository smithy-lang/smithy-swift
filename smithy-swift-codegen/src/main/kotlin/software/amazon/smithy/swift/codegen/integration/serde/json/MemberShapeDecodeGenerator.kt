/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration.serde.json

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.SetShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.SparseTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.customtraits.SwiftBoxTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeDecodeGeneratable
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.isBoxed
import software.amazon.smithy.swift.codegen.model.recursiveSymbol
import software.amazon.smithy.swift.codegen.model.toMemberNames
import software.amazon.smithy.swift.codegen.removeSurroundingBackticks

/*
Includes functions to help render conformance to Decodable protocol for shapes
 */
abstract class MemberShapeDecodeGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeDecodeGeneratable {
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
        val memberName = ctx.symbolProvider.toMemberNames(member).second
        if (member.hasTrait(SwiftBoxTrait::class.java)) {
            symbol = symbol.recursiveSymbol()
        }
        val decodeVerb = if (symbol.isBoxed()) "decodeIfPresent" else "decode"
        val decodedMemberName = "${memberName}Decoded"
        writer.write("let \$L = try \$L.$decodeVerb(\$L.self, forKey: .\$L)", decodedMemberName, containerName, symbol.name, memberName)
        renderAssigningDecodedMember(member, decodedMemberName)
    }

    private fun determineSymbolForShape(currShape: Shape, topLevel: Boolean): String {
        var mappedSymbol = when (currShape) {
            is MapShape -> {
                val currShapeKey = "String"

                val targetShape = ctx.model.expectShape(currShape.value.target)
                val valueEvaluated = determineSymbolForShape(targetShape, topLevel)
                val terminator = if (topLevel) "?" else ""
                "[$currShapeKey: $valueEvaluated$terminator]"
            }
            is ListShape -> {
                val targetShape = ctx.model.expectShape(currShape.member.target)
                val nestedShape = determineSymbolForShape(targetShape, topLevel)
                val terminator = if (topLevel) "?" else ""
                "[$nestedShape$terminator]"
            }
            is SetShape -> {
                val targetShape = ctx.model.expectShape(currShape.member.target)
                val nestedShape = determineSymbolForShape(targetShape, topLevel)
                "Set<$nestedShape>"
            }
            is TimestampShape -> {
                val tsFormat = currShape
                    .getTrait(TimestampFormatTrait::class.java)
                    .map { it.format }
                    .orElse(defaultTimestampFormat)
                if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) "Date" else "String"
            }
            else -> {
                "${ctx.symbolProvider.toSymbol(currShape)}"
            }
        }
        return mappedSymbol
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
        writer.write("throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: containerValues.codingPath + [CodingKeys.$memberName], debugDescription: \"date cannot be properly deserialized\"))")
    }

    fun renderDecodeListMember(
        shape: CollectionShape,
        memberName: String,
        containerName: String,
        topLevelMember: MemberShape,
        level: Int = 0
    ) {
        val isSparse = ctx.model.expectShape(topLevelMember.target).hasTrait<SparseTrait>()
        val symbolName = determineSymbolForShape(shape, true)
        val originalSymbol = ctx.symbolProvider.toSymbol(shape)
        val decodedMemberName = "${memberName.removeSurroundingBackticks()}Decoded$level"
        var insertMethod = when (shape) {
            is SetShape -> "insert"
            is ListShape -> "append"
            else -> "append"
        }
        val nestedTarget = ctx.model.expectShape(shape.member.target)
        if (level == 0) {
            insertMethod = when (ctx.model.expectShape(topLevelMember.target)) {
                is SetShape -> "insert"
                is ListShape -> "append"
                else -> "append"
            }
            val listContainerName = "${memberName}Container"
            val decodeVerb = if (originalSymbol.isBoxed()) "decodeIfPresent" else "decode"
            writer.write(
                "let \$L = try $containerName.$decodeVerb(\$L.self, forKey: .\$L)",
                listContainerName,
                symbolName,
                memberName
            )

            writer.write("var \$L:\$T = nil", decodedMemberName, originalSymbol)
            writer.openBlock("if let \$L = \$L {", "}", listContainerName, listContainerName) {
                writer.write("\$L = \$L()", decodedMemberName, originalSymbol)
                renderDecodeListTarget(nestedTarget, decodedMemberName, listContainerName, insertMethod, topLevelMember, shape.isSetShape, level)
            }
            renderAssigningDecodedMember(topLevelMember, decodedMemberName)
        } else {
            writer.openBlock("if let \$L = \$L {", "}", memberName, memberName) {
                val previousDecodedMemberName = "${memberName.removeSurroundingBackticks()}Decoded${level - 1}"
                val symbolName = determineSymbolForShape(shape, isSparse)
                writer.write("\$L = \$L()", previousDecodedMemberName, symbolName)
                renderDecodeListTarget(nestedTarget, containerName, memberName, insertMethod, topLevelMember, shape.isSetShape, level)
            }
        }
    }

    /*
    Simple assignment of the decode value to the member.
    Can be overridden to allow post processing of the decoded value before assigning it to the member.
     */
    open fun renderAssigningDecodedMember(topLevelMember: MemberShape, decodedMemberName: String) {
        val topLevelMemberName = ctx.symbolProvider.toMemberName(topLevelMember)
        writer.write("\$L = \$L", topLevelMemberName, decodedMemberName)
    }

    private fun renderDecodeListTarget(shape: Shape, decodedMemberName: String, collectionName: String, insertMethod: String, topLevelMember: MemberShape, isSetShape: Boolean, level: Int = 0) {
        val topLevelShape = ctx.model.expectShape(topLevelMember.target)
        val isSparse = topLevelShape.hasTrait<SparseTrait>()
        val iteratorName = "${shape.type.name.lowercase()}$level"
        val symbolName = determineSymbolForShape(shape, false)
        val terminator = "?"
        writer.openBlock("for $iteratorName in $collectionName {", "}") {
            when (shape) {
                is TimestampShape -> {
                    val tsFormat = shape
                        .getTrait(TimestampFormatTrait::class.java)
                        .map { it.format }
                        .orElse(defaultTimestampFormat)

                    if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) { // if decoding a double decode as normal from [[Date]].self
                        if (!isSparse && !isSetShape) {
                            writer.openBlock("if let $iteratorName = $iteratorName {", "}") {
                                writer.write("${decodedMemberName}$terminator.$insertMethod($iteratorName)")
                            }
                        } else {
                            writer.write("${decodedMemberName}$terminator.$insertMethod($iteratorName)")
                        }
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
                    writer.write("var \$L: \$L? = nil", nestedDecodedMemberName, symbolName)
                    renderDecodeListMember(shape, iteratorName, nestedDecodedMemberName, topLevelMember, level + 1)
                    writer.openBlock("if let $nestedDecodedMemberName = $nestedDecodedMemberName {", "}") {
                        writer.write("$decodedMemberName$terminator.$insertMethod($nestedDecodedMemberName)")
                    }
                }
                is MapShape -> {
                    val nestedDecodedMemberName = "${collectionName}Decoded$level"
                    writer.write("var \$L: \$L? = nil", nestedDecodedMemberName, symbolName)
                    renderDecodeMapMember(shape, iteratorName, nestedDecodedMemberName, topLevelMember, level + 1)
                    writer.openBlock("if let $nestedDecodedMemberName = $nestedDecodedMemberName {", "}") {
                        writer.write("$decodedMemberName$terminator.$insertMethod($nestedDecodedMemberName)")
                    }
                }
                else -> {
                    if (!isSparse && !isSetShape) {
                        writer.openBlock("if let $iteratorName = $iteratorName {", "}") {
                            writer.write("${decodedMemberName}$terminator.$insertMethod($iteratorName)")
                        }
                    } else {
                        writer.write("${decodedMemberName}$terminator.$insertMethod($iteratorName)")
                    }
                }
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
        val symbolName = determineSymbolForShape(shape, true)
        val originalSymbol = ctx.symbolProvider.toSymbol(shape)
        val decodedMemberName = "${memberName.removeSurroundingBackticks()}Decoded$level"
        val nestedTarget = ctx.model.expectShape(shape.value.target)
        if (level == 0) {
            val topLevelContainerName = "${memberName}Container"
            val decodeVerb = if (originalSymbol.isBoxed()) "decodeIfPresent" else "decode"
            writer.write(
                "let \$L = try $containerName.$decodeVerb(\$L.self, forKey: .\$L)",
                topLevelContainerName,
                symbolName,
                memberName
            )
            writer.write("var \$L: \$T = nil", decodedMemberName, originalSymbol)
            writer.openBlock("if let \$L = \$L {", "}", topLevelContainerName, topLevelContainerName) {
                writer.write("\$L = \$L()", decodedMemberName, originalSymbol)
                renderDecodeMapTarget(topLevelContainerName, decodedMemberName, nestedTarget, topLevelMember, level)
            }
            renderAssigningDecodedMember(topLevelMember, decodedMemberName)
        } else {
            writer.openBlock("if let \$L = \$L {", "}", memberName, memberName) {
                val previousDecodedMemberName = "${memberName.removeSurroundingBackticks()}Decoded${level - 1}"
                val symbolName = determineSymbolForShape(shape, false)
                writer.write("\$L = \$L()", containerName, symbolName)
                renderDecodeMapTarget(memberName, containerName, nestedTarget, topLevelMember, level)
            }
        }
    }

    private fun renderDecodeMapTarget(
        mapName: String,
        decodedMemberName: String,
        valueTargetShape: Shape,
        topLevelMember: MemberShape,
        level: Int = 0
    ) {
        val topLevelShape = ctx.model.expectShape(topLevelMember.target)
        val isSparse = topLevelShape.hasTrait<SparseTrait>()
        val valueIterator = "${valueTargetShape.id.name.lowercase()}$level"
        val symbolName = determineSymbolForShape(valueTargetShape, false)
        val terminator = "?"
        writer.openBlock("for (key$level, $valueIterator) in $mapName {", "}") {
            when (valueTargetShape) {
                is CollectionShape -> {
                    val nestedDecodedMemberName = "${valueIterator}Decoded$level"
                    writer.write("var \$L: \$L? = nil", nestedDecodedMemberName, symbolName)
                    renderDecodeListMember(valueTargetShape, valueIterator, nestedDecodedMemberName, topLevelMember, level + 1)
                    writer.write("$decodedMemberName?[key$level] = $nestedDecodedMemberName")
                }
                is MapShape -> {
                    val nestedDecodedMemberName = "${valueIterator}Decoded$level"
                    writer.write("var \$L: \$L? = nil", nestedDecodedMemberName, symbolName)
                    renderDecodeMapMember(valueTargetShape, valueIterator, nestedDecodedMemberName, topLevelMember, level + 1)
                    writer.write("$decodedMemberName?[key$level] = $nestedDecodedMemberName")
                }
                is TimestampShape -> {
                    val tsFormat = valueTargetShape
                        .getTrait(TimestampFormatTrait::class.java)
                        .map { it.format }
                        .orElse(defaultTimestampFormat)

                    if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) { // if decoding a double decode as normal from [[Date]].self
                        if (!isSparse) {
                            writer.openBlock("if let $valueIterator = $valueIterator {", "}") {
                                writer.write("${decodedMemberName}$terminator[key$level] = $valueIterator")
                            }
                        } else {
                            writer.write("${decodedMemberName}$terminator[key$level] = $valueIterator")
                        }
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
                else -> {
                    if (!isSparse) {
                        writer.openBlock("if let $valueIterator = $valueIterator {", "}") {
                            writer.write("${decodedMemberName}$terminator[key$level] = $valueIterator")
                        }
                    } else {
                        writer.write("${decodedMemberName}$terminator[key$level] = $valueIterator")
                    }
                }
            }
        }
    }
}
