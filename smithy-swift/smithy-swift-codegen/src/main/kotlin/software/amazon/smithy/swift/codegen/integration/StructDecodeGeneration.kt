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
import software.amazon.smithy.model.shapes.*
import software.amazon.smithy.model.traits.BoxTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.defaultName
import software.amazon.smithy.swift.codegen.isRecursiveMember
import software.amazon.smithy.swift.codegen.recursiveSymbol
import java.sql.Time

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

    fun render() {
        var valuesContainer = "values"
        writer.openBlock("public init (from decoder: Decoder) throws {", "}") {
            writer.write("let \$L = try decoder.container(keyedBy: CodingKeys.self)", valuesContainer)
            members.forEach { member ->
                val target = ctx.model.expectShape(member.target)
                val memberName = member.memberName
                when (target) {
                    is CollectionShape -> renderDecodeListMember(member, memberName, valuesContainer)
                    is MapShape -> {
                        //TODO
                        writer.write("$memberName = nil")
                    }
                    is TimestampShape -> {
                        val tsFormat = member
                            .getTrait(TimestampFormatTrait::class.java)
                            .map { it.format }
                            .orElse(defaultTimestampFormat)
                        if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS){
                            writeDecodeForPrimitive(target, member, valuesContainer)
                        } else {
                            val dateSymbol = getDateSymbolName(tsFormat)
                            writer.write("let dateString = try $valuesContainer.decodeIfPresent(\$L.self, forKey: .\$L)", dateSymbol, memberName)
                            val formatterName = "${memberName}Formatter"
                            writeDateFormatter(formatterName, tsFormat, writer)
                            writer.write("\$L = \$L.date(from: dateString)", memberName, formatterName)
                        }

                    }
                    else -> writeDecodeForPrimitive(target, member, valuesContainer)
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

    private fun getDateSymbolName(tsFormat: TimestampFormatTrait.Format): String {
        return when(tsFormat) {
            TimestampFormatTrait.Format.EPOCH_SECONDS -> "Date"
            TimestampFormatTrait.Format.DATE_TIME -> "String"
            TimestampFormatTrait.Format.HTTP_DATE -> "String"
            else -> throw CodegenException("unknown timestamp format: $tsFormat")
        }
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

    private fun renderDecodeListMember(member: MemberShape, memberName: String, containerName: String, level: Int = 0) {
        val target = ctx.model.expectShape(member.target)
        val symbolName = ctx.symbolProvider.toSymbol(target).name
        when (target) {
            is CollectionShape -> {
                val nestedTarget = ctx.model.expectShape(target.member.target)
                renderDecodeListTarget(ctx, memberName, containerName, nestedTarget, member, level)
            }
            // this only gets called in a recursive loop where there is a map nested deeply inside a list
            is MapShape -> renderDecodeListTarget(ctx, memberName, containerName, target, member, level)
            else -> writeDecodeForPrimitive(target, member, containerName)
        }
    }

    private fun renderDecodeListTarget(
        ctx: ProtocolGenerator.GenerationContext,
        collectionName: String,
        topLevelContainerName: String,
        targetShape: Shape,
        memberShape: MemberShape,
        level: Int = 0
    ) {
        val target = ctx.model.expectShape(memberShape.target)
        val symbol = ctx.symbolProvider.toSymbol(target)
        val iteratorName = "${targetShape.defaultName().toLowerCase()}$level"

            when (targetShape) {
                is TimestampShape -> {

                    val tsFormat = targetShape
                        .getTrait(TimestampFormatTrait::class.java)
                        .map { it.format }
                        .orElse(defaultTimestampFormat)
                    if(tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) { //if decoding a double decode as normal from [[Date]].self
                        writeDecodeForPrimitive(targetShape, memberShape, topLevelContainerName)
                    } else { //decode date as a string manually
                        val nestedContainerName = "${collectionName}Container"
                        val listContainer = "${collectionName}List"
                        val symbolName = getDateSymbolName(tsFormat)
                        writer.write("let \$L = try \$L.decodeIfPresent([\$L].self, forKey: .\$L)", nestedContainerName, topLevelContainerName, symbolName, collectionName)
                        writer.write("var \$L = \$L()", listContainer, symbol.name)
                        writer.openBlock("for timestamp in $nestedContainerName {", "}") {
                            val formatterName = "${collectionName}Formatter"
                            writeDateFormatter(formatterName, tsFormat, writer)
                            writer.openBlock("guard let date = $formatterName.date(from: timestamp) else {", "}") {
                                writer.write("throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: $topLevelContainerName.codingPath + [CodingKeys.$collectionName], debugDescription: \"date cannot be properly deserialized\"))")
                            }
                            writer.write("$listContainer.append(date)")
                        }
                    }
                }
                else -> {

                    writer.write("\$1L = try $topLevelContainerName.decodeIfPresent(\$3L.self, .\$2L)", collectionName, collectionName, symbol.name)
                }
            }
    }

}