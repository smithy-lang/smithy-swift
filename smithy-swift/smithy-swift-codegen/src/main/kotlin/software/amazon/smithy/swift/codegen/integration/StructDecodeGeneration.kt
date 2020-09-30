/*
 *
 *  * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  *
 *  * Licensed under the Apache License, Version 2.0 (the "License").
 *  * You may not use this file except in compliance with the License.
 *  * A copy of the License is located at
 *  *
 *  *  http://aws.amazon.com/apache2.0
 *  *
 *  * or in the "license" file accompanying this file. This file is distributed
 *  * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 *  * express or implied. See the License for the specific language governing
 *  * permissions and limitations under the License.
 *
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.TopologicalIndex
import software.amazon.smithy.model.neighbor.RelationshipType
import software.amazon.smithy.model.neighbor.Walker
import software.amazon.smithy.model.shapes.*
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.*

/**
 * Generates decode function for members bound to the payload.
 *
 * e.g.
 * ```
    public init (from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        member1 = try values.decodeIfPresent(Int.self, forKey: .member1)
        let intListContainer = try values.decodeIfPresent([Int].self, forKey: .intList)
        var intListDecoded0 = [Int]()
        if let intListContainer = intListContainer {
            for integer0 in intListContainer {
                intListDecoded0.append(integer0)
            }
        }
        intList = intListDecoded0
        let intMapContainer = try values.decodeIfPresent([String:Int].self, forKey: .intMap)
        var intMapDecoded0 = [String:Int]()
        if let intMapContainer = intMapContainer {
            for (key0, integer0) in intMapContainer {
                intMapDecoded0[key0] = integer0
            }
        }
        intMap = intMapDecoded0
    }
 * ```
 */
class StructDecodeGeneration(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) {
    var currentMember: MemberShape? = null

    fun render() {
        var containerName = "values"
        writer.openBlock("public init (from decoder: Decoder) throws {", "}") {
            writer.write("let \$L = try decoder.container(keyedBy: CodingKeys.self)", containerName)
            members.forEach { member ->
                val target = ctx.model.expectShape(member.target)
                val memberName = member.memberName
                currentMember = member
                when (target) {
                    is CollectionShape -> renderDecodeListMember(target, memberName, containerName)
                    is MapShape -> renderDecodeMapMember(target, memberName, containerName)
                    is TimestampShape -> {
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
                            val decodableMemberName = "${memberName}Decoded"
                            writer.write("let \$L = try $containerName.decodeIfPresent(\$L.self, forKey: .\$L)", dateString, dateSymbol, memberName)
                            writer.write("var \$L: \$T = nil", decodableMemberName, originalSymbol)
                            writer.openBlock("if let \$L = \$L {", "}", dateString, dateString) {
                                val formatterName = "${memberName}Formatter"
                                writeDateFormatter(formatterName, tsFormat, writer)
                                writer.write("\$L = \$L.date(from: \$L)", decodableMemberName, formatterName, dateString)
                            }
                            writer.write("\$L = \$L", memberName, decodableMemberName)
                        }
                    }
                    else -> writeDecodeForPrimitive(target, member, containerName)
                }
            }
        }
    }

    private fun writeDecodeForPrimitive(shape: Shape, member: MemberShape, containerName: String) {
        var symbol = ctx.symbolProvider.toSymbol(shape)
        val memberName = member.memberName
        val topologicalIndex = TopologicalIndex.of(ctx.model)
        if (member.isRecursiveMember(topologicalIndex)) {
            symbol = symbol.recursiveSymbol()
        }
        writer.write("$memberName = try $containerName.decodeIfPresent(\$L.self, forKey: .\$L)", symbol.name, memberName)
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

    private fun renderDecodingError(memberName: String) {
        writer.write("throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: values.codingPath + [CodingKeys.$memberName], debugDescription: \"date cannot be properly deserialized\"))")
    }

    private fun renderDecodeListMember(
        shape: CollectionShape,
        memberName: String,
        containerName: String,
        level: Int = 0
    ) {
        val symbolName = getSymbolName(shape)
        val originalSymbol = ctx.symbolProvider.toSymbol(shape)
        val decodedMemberName = "${memberName}Decoded$level"
        val topLevelMemberName = currentMember!!.memberName
        val insertMethod = when (ctx.model.expectShape(currentMember!!.target)) {
            is SetShape -> "insert"
            is ListShape -> "append"
            else -> "append"
        }
        val nestedTarget = ctx.model.expectShape(shape.member.target)
        if (level == 0) {
            val listContainerName = "${memberName}Container"
            writer.write(
                "let \$L = try values.decodeIfPresent(\$L.self, forKey: .\$L)",
                listContainerName,
                symbolName,
                memberName
            )
            writer.write("var \$L = \$L()", decodedMemberName, originalSymbol)
            writer.openBlock("if let \$L = \$L {", "}", listContainerName, listContainerName) {
                renderDecodeListTarget(nestedTarget, decodedMemberName, listContainerName, insertMethod, level)
            }
            writer.write("\$L = \$L", topLevelMemberName, decodedMemberName)
        } else {
            val isBoxed = ctx.symbolProvider.toSymbol(nestedTarget).isBoxed()
            if(isBoxed) {
                writer.openBlock("if let \$L = \$L {", "}", memberName, memberName) {
                    renderDecodeListTarget(nestedTarget, containerName, memberName, insertMethod, level)
                }
            } else {
                renderDecodeListTarget(nestedTarget, containerName, memberName, insertMethod, level)
            }
        }
    }

    private fun renderDecodeListTarget(shape: Shape, decodedMemberName: String, collectionName: String, insertMethod: String, level: Int = 0) {
        val iteratorName = "${shape.type.name.toLowerCase()}$level"
        val topLevelMemberName = currentMember!!.memberName
        val originalSymbol = ctx.symbolProvider.toSymbol(shape)
        writer.openBlock("for $iteratorName in $collectionName {", "}") {
            when (shape) {
                is TimestampShape -> {
                    val tsFormat = shape
                        .getTrait(TimestampFormatTrait::class.java)
                        .map { it.format }
                        .orElse(defaultTimestampFormat)

                    if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) { // if decoding a double decode as normal from [[Date]].self
                        writer.write("$decodedMemberName.$insertMethod($iteratorName)")
                    } else { // decode date as a string manually
                        val formatterName = "${iteratorName}Formatter"
                        writeDateFormatter(formatterName, tsFormat, writer)
                        val dateName = "date$level"
                        writer.openBlock("guard let $dateName = $formatterName.date(from: $iteratorName) else {", "}") {
                            renderDecodingError(topLevelMemberName)
                        }
                        writer.write("$decodedMemberName.$insertMethod($dateName)")
                    }
                }
                is CollectionShape -> {
                    val nestedDecodedMemberName = "${iteratorName}Decoded$level"
                    writer.write("var \$L = \$L()", nestedDecodedMemberName, originalSymbol)
                    renderDecodeListMember(shape, iteratorName, nestedDecodedMemberName, level + 1)
                    writer.write("$decodedMemberName.$insertMethod($nestedDecodedMemberName)")
                }
                is MapShape -> {
                    val nestedDecodedMemberName = "${collectionName}Decoded$level"
                    writer.write("var \$L = \$L()", nestedDecodedMemberName, originalSymbol)
                    renderDecodeMapMember(shape, iteratorName, nestedDecodedMemberName, level + 1)
                    writer.write("$decodedMemberName.$insertMethod($nestedDecodedMemberName)")
                }
                else -> writer.write("$decodedMemberName.$insertMethod($iteratorName)")
            }
        }
    }

    private fun renderDecodeMapMember(shape: MapShape, memberName: String, containerName: String, level: Int = 0) {
        val symbolName = getSymbolName(shape)
        val originalSymbol = ctx.symbolProvider.toSymbol(shape)
        val decodedMemberName = "${memberName}Decoded$level"
        val topLevelMemberName = currentMember!!.memberName
        val nestedTarget = ctx.model.expectShape(shape.value.target)
        if (level == 0) {
            val topLevelContainerName = "${memberName}Container"
            writer.write("let \$L = try values.decodeIfPresent(\$L.self, forKey: .\$L)",
                topLevelContainerName,
                symbolName,
                memberName)
            writer.write("var \$L = \$L()", decodedMemberName, originalSymbol)
            writer.openBlock("if let \$L = \$L {", "}", topLevelContainerName, topLevelContainerName) {
                renderDecodeMapTarget(topLevelContainerName, decodedMemberName, nestedTarget, level)
            }
            writer.write("\$L = \$L", topLevelMemberName, decodedMemberName)
        } else {
            renderDecodeMapTarget(memberName, containerName, nestedTarget, level)
        }
    }

    private fun renderDecodeMapTarget(
        mapName: String,
        decodedMemberName: String,
        valueTargetShape: Shape,
        level: Int = 0
    ) {
        val valueIterator = "${valueTargetShape.defaultName().toLowerCase()}$level"
        val topLevelMemberName = currentMember!!.memberName
        val originalSymbol = ctx.symbolProvider.toSymbol(valueTargetShape)
        writer.openBlock("for (key$level, $valueIterator) in $mapName {", "}") {
            when (valueTargetShape) {
                is CollectionShape -> {
                    val originalSymbol = ctx.symbolProvider.toSymbol(valueTargetShape)
                    val nestedDecodedMemberName = "${valueIterator}Decoded$level"
                    writer.write("var \$L = \$L()", nestedDecodedMemberName, originalSymbol)
                    renderDecodeListMember(valueTargetShape, valueIterator, nestedDecodedMemberName, level + 1)
                    writer.write("$decodedMemberName[key$level] = $nestedDecodedMemberName")
                }
                is MapShape -> {
                    val nestedDecodedMemberName = "${valueIterator}Decoded$level"
                    writer.write("var \$L = \$L()", nestedDecodedMemberName, originalSymbol)
                    renderDecodeMapMember(valueTargetShape, valueIterator, nestedDecodedMemberName, level + 1)
                    writer.write("$decodedMemberName[key$level] = $nestedDecodedMemberName")
                }
                is TimestampShape -> {
                    val tsFormat = valueTargetShape
                        .getTrait(TimestampFormatTrait::class.java)
                        .map { it.format }
                        .orElse(defaultTimestampFormat)

                    if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) { // if decoding a double decode as normal from [[Date]].self
                        writer.write("$decodedMemberName[key$level] = $valueIterator")
                    } else { // decode date as a string manually
                        val formatterName = "${mapName}Formatter"
                        writeDateFormatter(formatterName, tsFormat, writer)
                        val dateName = "date$level"
                        writer.openBlock("guard let $dateName = $formatterName.date(from: $valueIterator) else {", "}") {
                            renderDecodingError(topLevelMemberName)
                        }
                        writer.write("$decodedMemberName[key$level] = $dateName")
                    }
                }
                else -> writer.write("$decodedMemberName[key$level] = $valueIterator")
            }
        }
    }
}
