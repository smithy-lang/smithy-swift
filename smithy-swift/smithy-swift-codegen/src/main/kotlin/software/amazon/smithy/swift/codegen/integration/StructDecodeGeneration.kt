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
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.defaultName
import software.amazon.smithy.swift.codegen.isRecursiveMember
import software.amazon.smithy.swift.codegen.recursiveSymbol

/**
 * Generates decode function for members bound to the payload.
 *
 * e.g.
 * ```
 *    public init decode(from decoder: Decoder) throws {
 *       let values = decoder.container(keyedBy: CodingKeys.self)
 *       booleanList = try values.decode([Bool].self, forKey: .booleanList)
 *       enumList = try values.decode([MyEnum.self], forKey: .enumList)
 *       integerList = try values.decode([Int].self, forKey: .integerList)
 *   }
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
                        if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS){
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
        if(member.isRecursiveMember(topologicalIndex)) {
            symbol = symbol.recursiveSymbol()
        }
        writer.write("$memberName = try $containerName.decodeIfPresent(\$L.self, forKey: .\$L)", symbol.name, memberName)
    }

    //TODO remove this when we switch to a custom date type as this wont be necessary anymore
    private fun getSymbolName(shape: Shape): String {
        val symbol = ctx.symbolProvider.toSymbol(shape)
        val walker = Walker(ctx.model)
        if (symbol.name.contains("Date")) {
            //if symbol name contains the Date symbol, check timestamp format. if the timestamp format is not epoch seconds,
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
        when(tsFormat) {
            TimestampFormatTrait.Format.EPOCH_SECONDS -> writer.write("let \$L = DateFormatter()", formatterName)
            // FIXME return to this to figure out when to use fractional seconds precision in more general sense after we switch
            // to custom date type
            TimestampFormatTrait.Format.DATE_TIME -> writer.write("let \$L = DateFormatter.iso8601DateFormatterWithFractionalSeconds", formatterName)
            TimestampFormatTrait.Format.HTTP_DATE -> writer.write("let \$L = DateFormatter.rfc5322DateFormatter", formatterName)
            else -> throw CodegenException("unknown timestamp format: $tsFormat")
        }
    }

    private fun renderDecodingError(memberName: String) {
        writer.write("throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: values.codingPath + [CodingKeys.$memberName], debugDescription: \"date cannot be properly deserialized\"))")
    }

    private fun renderDecodeListMember(shape: Shape, memberName: String, containerName: String, level: Int = 0) {
        val symbolName = getSymbolName(shape)
        val originalSymbol = ctx.symbolProvider.toSymbol(shape)
        val decodedMemberName = "${memberName}Decoded${level}"
        val topLevelMemberName = currentMember!!.memberName
        val insertMethod = when(ctx.model.expectShape(currentMember!!.target)) {
            is SetShape -> "insert"
            is ListShape -> "append"
            else -> ""
        }
        when (shape) {
            is CollectionShape -> {
                if (level == 0) {
                    val listContainerName = "${memberName}Container"
                    writer.write("let \$L = try values.decodeIfPresent(\$L.self, forKey: .\$L)",
                        listContainerName,
                        symbolName,
                        memberName)

                    writer.write("var \$L = \$L()", decodedMemberName, originalSymbol)
                    writer.openBlock("if let \$L = \$L {", "}", listContainerName, listContainerName) {
                        renderDecodeList(memberName, listContainerName, decodedMemberName, shape, level)
                    }
                    writer.write("\$L = \$L", topLevelMemberName, decodedMemberName)

                } else {
                    writer.write("var \$L = \$L()", decodedMemberName, originalSymbol)
                    renderDecodeList(memberName, memberName, decodedMemberName, shape, level)
                    writer.write("$containerName.$insertMethod($decodedMemberName)")
                }
            }
            is TimestampShape -> {
                val tsFormat = shape
                    .getTrait(TimestampFormatTrait::class.java)
                    .map { it.format }
                    .orElse(defaultTimestampFormat)

                if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) { //if decoding a double decode as normal from [[Date]].self
                    writer.write("$containerName.$insertMethod($memberName)")
                } else { //decode date as a string manually

                    val formatterName = "${memberName}Formatter"
                    writeDateFormatter(formatterName, tsFormat, writer)
                    val dateName = "date${level - 1}"
                    writer.openBlock("guard let $dateName = $formatterName.date(from: $memberName) else {", "}") {
                        renderDecodingError(topLevelMemberName)
                    }
                    writer.write("$containerName.$insertMethod($dateName)")
                }
            }
            // this only gets called in a recursive loop where there is a map nested deeply inside a list
            is MapShape -> renderDecodeList(memberName, containerName, decodedMemberName, shape, level)
            else -> writer.write("$containerName.$insertMethod($memberName)")
        }
    }

    private fun renderDecodeList(
        collectionName: String,
        topLevelContainerName: String,
        decodedMemberName: String,
        targetShape: Shape,
        level: Int = 0
    ) {

        val symbolName = getSymbolName(targetShape)
        val iteratorName = "${targetShape.defaultName().toLowerCase()}$level"
        writer.openBlock("for $iteratorName in $topLevelContainerName {", "}") {
            when (targetShape) {
                is CollectionShape -> {
                    val nestedTarget = ctx.model.expectShape(targetShape.member.target)
                    renderDecodeListMember(nestedTarget, iteratorName, decodedMemberName, level + 1)
                }
                is TimestampShape -> {

                    val tsFormat = targetShape
                        .getTrait(TimestampFormatTrait::class.java)
                        .map { it.format }
                        .orElse(defaultTimestampFormat)
                    if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) {
                        //if decoding a double in seconds, decode as normal from [[Date]].self
                        writer.write("$decodedMemberName.append($collectionName)")
                    } else { //decode date as a string manually

                        val formatterName = "${collectionName}Formatter"
                        writeDateFormatter(formatterName, tsFormat, writer)
                        val dateName = "date${level - 1}"
                        writer.openBlock("guard let $dateName = $formatterName.date(from: $iteratorName) else {", "}") {
                           renderDecodingError(collectionName)
                        }
                        writer.write("$decodedMemberName.append($collectionName)")
                    }
                }
                is MapShape -> renderDecodeMapMember(targetShape, "key$level", topLevelContainerName, level+1)
                else -> {

                    writer.write(
                        "\$1L = try values.decodeIfPresent(\$3L.self, .\$2L)",
                        collectionName,
                        symbolName,
                        collectionName
                    )
                }
            }
        }
    }

    private fun renderDecodeMapMember(targetShape: Shape, keyName: String, containerName: String, level: Int = 0) {
        val symbolName = getSymbolName(targetShape)
        val originalSymbol = ctx.symbolProvider.toSymbol(targetShape)
        val decodedMemberName = "${keyName}Decoded${level}"
        val topLevelMemberName = currentMember!!.memberName
        when (targetShape) {
            is CollectionShape -> {
                renderDecodeList(keyName, containerName, decodedMemberName, targetShape, level)
            }
            is TimestampShape -> {

                val tsFormat = targetShape
                    .getTrait(TimestampFormatTrait::class.java)
                    .map { it.format }
                    .orElse(defaultTimestampFormat)

                if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) { //if decoding a double decode as normal from [[Date]].self
                    writer.write("$decodedMemberName[key$level] = $keyName")
                } else { //decode date as a string manually

                    val formatterName = "${keyName}Formatter"
                    writeDateFormatter(formatterName, tsFormat, writer)
                    val dateName = "date${level}"
                    writer.openBlock("guard let $dateName = $formatterName.date(from: $keyName) else {", "}") {
                        renderDecodingError(topLevelMemberName)
                    }
                    writer.write("$decodedMemberName[key$level] = $dateName")
                }
            }
            is MapShape -> {
                if (level == 0) {
                    val topLevelContainerName = "${keyName}Container"
                    writer.write("let \$L = try values.decodeIfPresent(\$L.self, forKey: .\$L)",
                        topLevelContainerName,
                        symbolName,
                        keyName)
                    writer.write("var \$L = \$L()", decodedMemberName, originalSymbol)
                    writer.openBlock("if let \$L = \$L {", "}", topLevelContainerName, topLevelContainerName) {
                        renderDecodeMap(topLevelContainerName, decodedMemberName, targetShape.value, level)
                    }
                    writer.write("\$L = \$L", topLevelMemberName, decodedMemberName)
                } else {
                    writer.write("var \$L = \$L()", decodedMemberName, originalSymbol)
                    renderDecodeMap(keyName, decodedMemberName, targetShape.value, level)
                    writer.write("$containerName[key${level-1}] = $decodedMemberName")
                }
            }
            else -> writer.write("$decodedMemberName[key$level] = $keyName")
        }
    }

    private fun renderDecodeMap(
        mapName: String,
        decodedMemberName: String,
        valueTargetShape: Shape,
        level: Int = 0
    ) {
        val valueIterator = "${valueTargetShape.defaultName().toLowerCase()}$level"
        val target = when (valueTargetShape) {
            is MemberShape -> ctx.model.expectShape(valueTargetShape.target)
            else -> valueTargetShape
        }
        val topLevelMemberName = currentMember!!.memberName
        writer.openBlock("for (key$level, $valueIterator) in $mapName {", "}") {
            when (target) {
                is CollectionShape -> {
                    val nestedTarget = ctx.model.expectShape(target.member.target)
                    renderDecodeListMember(
                        nestedTarget,
                        valueIterator,
                        mapName,
                        level + 1
                    )
                    writer.write("$decodedMemberName[key$level] = $valueIterator")
                }
                is MapShape -> {
                    //val nestedTarget = ctx.model.expectShape(target.value.target)
                    renderDecodeMapMember(
                        target,
                        valueIterator,
                        decodedMemberName,
                        level + 1
                    )
                }
                is TimestampShape -> {
                    val tsFormat = target
                        .getTrait(TimestampFormatTrait::class.java)
                        .map { it.format }
                        .orElse(defaultTimestampFormat)

                    if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) { //if decoding a double decode as normal from [[Date]].self
                        writer.write("$decodedMemberName[key$level] = $valueIterator")
                    } else { //decode date as a string manually
                        val formatterName = "${mapName}Formatter"
                        writeDateFormatter(formatterName, tsFormat, writer)
                        val dateName = "date${level}"
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