/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration.serde.json

import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.SetShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.SparseTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeDecodeGeneratable
import software.amazon.smithy.swift.codegen.integration.serde.TimestampDecodeGenerator
import software.amazon.smithy.swift.codegen.integration.serde.TimestampHelpers
import software.amazon.smithy.swift.codegen.model.defaultValue
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.isBoxed
import software.amazon.smithy.swift.codegen.model.toMemberNames
import software.amazon.smithy.swift.codegen.removeSurroundingBackticks

/*
Includes functions to help render conformance to Decodable protocol for shapes
 */
abstract class MemberShapeDecodeGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format,
    private val path: String
) : MemberShapeDecodeGeneratable {
    fun renderDecodeForTimestamp(ctx: ProtocolGenerator.GenerationContext, target: Shape, member: MemberShape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val timestampFormat = TimestampHelpers.getTimestampFormat(member, target, defaultTimestampFormat)
        val codingKey = writer.format(".\$L", memberName)
        val decodedMemberName = writer.format("\$LDecoded", memberName)
        TimestampDecodeGenerator(
            decodedMemberName,
            containerName,
            codingKey,
            timestampFormat,
            true
        ).generate(writer)
        renderAssigningDecodedMember(member, decodedMemberName)
    }

    fun writeDecodeForPrimitive(shape: Shape, member: MemberShape, containerName: String, ignoreDefaultValues: Boolean = false) {
        var symbol = ctx.symbolProvider.toSymbol(member)
        val memberName = ctx.symbolProvider.toMemberNames(member).second
        val defaultValue = symbol.defaultValue()
        val decodeVerb = if (symbol.isBoxed() || !defaultValue.isNullOrEmpty()) "decodeIfPresent" else "decode"
        val decodedMemberName = "${memberName}Decoded"

        // no need to assign nil to a member that is optional
        val defaultValueLiteral = if (!ignoreDefaultValues && defaultValue != null && defaultValue != "nil") " ?? $defaultValue" else ""

        writer.write("let \$L = try \$L.$decodeVerb(\$N.self, forKey: .\$L)$defaultValueLiteral", decodedMemberName, containerName, symbol, memberName)
        renderAssigningDecodedMember(member, decodedMemberName)
    }

    private fun determineSymbolForShape(currShape: Shape, topLevel: Boolean): String {
        var mappedSymbol = when (currShape) {
            is MapShape -> {
                val mapIsSparse = currShape.hasTrait<SparseTrait>()
                val targetShape = ctx.model.expectShape(currShape.value.target)
                val valueEvaluated = determineSymbolForShape(targetShape, topLevel)
                val terminator = if (topLevel || mapIsSparse) "?" else ""
                "[${SwiftTypes.String}: $valueEvaluated$terminator]"
            }
            is ListShape -> {
                val listIsSparse = currShape.hasTrait<SparseTrait>()
                val targetShape = ctx.model.expectShape(currShape.member.target)
                val nestedShape = determineSymbolForShape(targetShape, topLevel)
                val terminator = if (topLevel || listIsSparse) "?" else ""
                "[$nestedShape$terminator]"
            }
            is SetShape -> {
                val targetShape = ctx.model.expectShape(currShape.member.target)
                val nestedShape = determineSymbolForShape(targetShape, topLevel)
                "${SwiftTypes.Set}<$nestedShape>"
            }
            is TimestampShape -> {
                val timestampFormat = TimestampHelpers.getTimestampFormat(currShape, null, defaultTimestampFormat)
                if (timestampFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) "${ClientRuntimeTypes.Core.Date}" else "${SwiftTypes.String}"
            }
            else -> {
                "${ctx.symbolProvider.toSymbol(currShape)}"
            }
        }
        return mappedSymbol
    }

    fun renderDecodeListMember(
        shape: CollectionShape,
        memberName: String,
        containerName: String,
        topLevelMember: MemberShape,
        parentMember: Shape,
        level: Int = 0
    ) {
        val symbolName = determineSymbolForShape(shape, true)
        val originalSymbol = ctx.symbolProvider.toSymbol(parentMember)
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
            val listContainerName = "${memberName.removeSurroundingBackticks()}Container"
            val decodeVerb = if (originalSymbol.isBoxed()) "decodeIfPresent" else "decode"
            writer.write(
                "let \$L = try $containerName.$decodeVerb(\$L.self, forKey: .\$L)",
                listContainerName,
                symbolName,
                memberName
            )

            writer.write("var \$L:\$T = nil", decodedMemberName, originalSymbol)
            writer.openBlock("if let \$L = \$L {", "}", listContainerName, listContainerName) {
                writer.write("\$L = \$N()", decodedMemberName, originalSymbol)
                renderDecodeListTarget(nestedTarget, decodedMemberName, listContainerName, insertMethod, topLevelMember, shape, level)
            }
            renderAssigningDecodedMember(topLevelMember, decodedMemberName)
        } else {
            writer.openBlock("if let \$L = \$L {", "}", memberName, memberName) {
                val previousDecodedMemberName = "${memberName.removeSurroundingBackticks()}Decoded${level - 1}"
                val symbolName = determineSymbolForShape(shape, false)
                writer.write("\$L = \$L()", previousDecodedMemberName, symbolName)
                renderDecodeListTarget(nestedTarget, containerName, memberName, insertMethod, topLevelMember, shape, level)
            }
        }
    }

    /*
    Simple assignment of the decode value to the member.
    Can be overridden to allow post processing of the decoded value before assigning it to the member.
     */
    open fun renderAssigningDecodedMember(topLevelMember: MemberShape, decodedMemberName: String) {
        val topLevelMemberName = ctx.symbolProvider.toMemberName(topLevelMember)
        writer.write("\$L\$L = \$L", path, topLevelMemberName, decodedMemberName)
    }

    private fun renderDecodeListTarget(shape: Shape, decodedMemberName: String, collectionName: String, insertMethod: String, topLevelMember: MemberShape, parentMember: Shape, level: Int = 0) {
        val isSparse = parentMember.hasTrait<SparseTrait>()
        val iteratorName = "${shape.type.name.lowercase()}$level"
        val symbolName = determineSymbolForShape(shape, false)
        val terminator = "?"
        writer.openBlock("for $iteratorName in $collectionName {", "}") {
            when (shape) {
                is TimestampShape -> {
                    val timestampFormat = TimestampHelpers.getTimestampFormat(shape, null, defaultTimestampFormat)

                    if (timestampFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) { // if decoding a double decode as normal from [[Date]].self
                        if (!isSparse) {
                            writer.openBlock("if let $iteratorName = $iteratorName {", "}") {
                                writer.write("${decodedMemberName}$terminator.$insertMethod($iteratorName)")
                            }
                        } else {
                            writer.write("${decodedMemberName}$terminator.$insertMethod($iteratorName)")
                        }
                    } else { // decode date as a string manually
                        val dateName = "date$level"
                        val swiftTimestampName = TimestampHelpers.generateTimestampFormatEnumValue(timestampFormat)
                        if (!isSparse) {
                            writer.openBlock("if let $iteratorName = $iteratorName {", "}") {
                                writer.write(
                                    "let \$L = try containerValues.timestampStringAsDate(\$L, format: .\$L, forKey: .\$L)",
                                    dateName, iteratorName, swiftTimestampName, topLevelMember.memberName
                                )
                                writer.write("${decodedMemberName}$terminator.$insertMethod($dateName)")
                            }
                        } else {
                            writer.write(
                                "let \$L = try containerValues.timestampStringAsDate(\$L, format: .\$L, forKey: .\$L)",
                                dateName, iteratorName, swiftTimestampName, topLevelMember.memberName
                            )
                            writer.write("${decodedMemberName}$terminator.$insertMethod($dateName)")
                        }
                    }
                }
                is CollectionShape -> {
                    val nestedDecodedMemberName = "${iteratorName}Decoded$level"
                    writer.write("var \$L: \$L? = nil", nestedDecodedMemberName, symbolName)
                    renderDecodeListMember(shape, iteratorName, nestedDecodedMemberName, topLevelMember, parentMember, level + 1)
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
                    if (!isSparse) {
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
        val originalSymbol = ctx.symbolProvider.toSymbol(topLevelMember)
        val decodedMemberName = "${memberName.removeSurroundingBackticks()}Decoded$level"
        val nestedTarget = ctx.model.expectShape(shape.value.target)
        if (level == 0) {
            val topLevelContainerName = "${memberName.removeSurroundingBackticks()}Container"
            val decodeVerb = if (originalSymbol.isBoxed()) "decodeIfPresent" else "decode"
            writer.write(
                "let \$L = try $containerName.$decodeVerb(\$L.self, forKey: .\$L)",
                topLevelContainerName,
                symbolName,
                memberName
            )
            writer.write("var \$L: \$T = nil", decodedMemberName, originalSymbol)
            writer.openBlock("if let \$L = \$L {", "}", topLevelContainerName, topLevelContainerName) {
                writer.write("\$L = \$N()", decodedMemberName, originalSymbol)
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
                    renderDecodeListMember(valueTargetShape, valueIterator, nestedDecodedMemberName, topLevelMember, valueTargetShape.member, level + 1)
                    writer.write("$decodedMemberName?[key$level] = $nestedDecodedMemberName")
                }
                is MapShape -> {
                    val nestedDecodedMemberName = "${valueIterator}Decoded$level"
                    writer.write("var \$L: \$L? = nil", nestedDecodedMemberName, symbolName)
                    renderDecodeMapMember(valueTargetShape, valueIterator, nestedDecodedMemberName, topLevelMember, level + 1)
                    writer.write("$decodedMemberName?[key$level] = $nestedDecodedMemberName")
                }
                is TimestampShape -> {
                    val timestampFormat = TimestampHelpers.getTimestampFormat(valueTargetShape, null, defaultTimestampFormat)

                    if (timestampFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) { // if decoding a double decode as normal from [[Date]].self
                        if (!isSparse) {
                            writer.openBlock("if let $valueIterator = $valueIterator {", "}") {
                                writer.write("${decodedMemberName}$terminator[key$level] = $valueIterator")
                            }
                        } else {
                            writer.write("${decodedMemberName}$terminator[key$level] = $valueIterator")
                        }
                    } else { // decode date as a string manually
                        val dateName = "date$level"
                        val swiftTimestampName = TimestampHelpers.generateTimestampFormatEnumValue(timestampFormat)
                        writer.write(
                            "let \$L = try containerValues.timestampStringAsDate(\$L, format: .\$L, forKey: .\$L)",
                            dateName, valueIterator, swiftTimestampName, topLevelMember.memberName
                        )
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
