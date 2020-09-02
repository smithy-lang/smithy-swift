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
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.shapes.*
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.defaultName
import java.lang.reflect.Member
import java.sql.Time

/**
 * Generates encode function for members bound to the payload.
 *
 * e.g.
 * ```
 *    public func encode(to encoder: Encoder) throws {
 *       var container = encoder.container(keyedBy: CodingKeys.self)
 *       try container.encode(booleanList, forKey: .booleanList)
 *       try container.encode(enumList, forKey: .enumList)
 *       try container.encode(integerList, forKey: .integerList)
 *       try container.encode(nestedStringList, forKey: .nestedStringList)
 *       try container.encode(stringList, forKey: .stringList)
 *       try container.encode(stringSet, forKey: .stringSet)
 *       try container.encode(structureList, forKey: .structureList)
 *       try container.encode(timestampList, forKey: .timestampList)
 *   }
 * ```
 */
class StructEncodeGeneration(private val ctx: ProtocolGenerator.GenerationContext,
                             private val members: List<MemberShape>,
                             private val writer: SwiftWriter,
                             private val defaultTimestampFormat: TimestampFormatTrait.Format) {
    fun render() {
        writer.openBlock("public func encode(to encoder: Encoder) throws {", "}") {
            writer.write("var container = encoder.container(keyedBy: CodingKeys.self)")
            members.forEach { member ->
                val target = ctx.model.expectShape(member.target)
                val memberName = member.memberName
                when (target.type) {
                    ShapeType.SET, ShapeType.LIST -> renderEncodeListMember(member)
                    ShapeType.TIMESTAMP -> {
                        val dateExtension = encodeDateType(member)

                        writer.write("try container.encode($dateExtension, forKey: .\$L)", memberName)
                    }
                    else -> {
                        writer.write("try container.encode(\$L, forKey: .\$L)", memberName, memberName)
                    }
                }
            }
        }
    }

    private fun encodeDateType(member: MemberShape): String {
        val memberName = member.memberName
        val tsFormat = member
            .getTrait(TimestampFormatTrait::class.java)
            .map { it.format }
            .orElse(defaultTimestampFormat)
       return dateString(tsFormat, memberName)
    }

    private fun dateString(tsFormat: TimestampFormatTrait.Format, memberName: String): String {
        when (tsFormat) {
            TimestampFormatTrait.Format.EPOCH_SECONDS -> return "${memberName}?.timeIntervalSince1970"
            TimestampFormatTrait.Format.DATE_TIME -> return "${memberName}?.iso8601FractionalSecondsString()"
            TimestampFormatTrait.Format.HTTP_DATE -> return "${memberName}?.rfc5322String()"
            else -> throw CodegenException("unknown timestamp format: $tsFormat")
        }
    }

    private fun renderEncodeListMember(member: MemberShape) {
        val memberName = member.memberName

        val collectionShape = ctx.model.expectShape(member.target) as CollectionShape
        val targetShape = ctx.model.expectShape(collectionShape.member.target)
        val targetShapeName = targetShape.defaultName().toLowerCase()

        when (targetShape) {
            is CollectionShape, is TimestampShape -> {
                val topLevelContainerName = "${memberName}Container"
                writer.write("var $topLevelContainerName = container.nestedUnkeyedContainer(forKey: .\$L)", memberName)
                renderEncodeList(ctx, memberName, topLevelContainerName, targetShape, writer)
            }
            is MapShape -> renderEncodeMap(targetShape.value)
            else -> writer.write("try container.encode(\$1L, forKey: .\$1L)", memberName)
        }
    }

    private fun renderEncodeList(
        ctx: ProtocolGenerator.GenerationContext,
        collectionName: String,
        topLevelContainerName: String,
        targetShape: Shape,
        writer: SwiftWriter,
        level: Int = 0
    ) {
        val iteratorName = "${targetShape.defaultName().toLowerCase()}${level}"

        when (targetShape) {
            is TimestampShape -> {
                val bindingIndex = ctx.model.getKnowledge(HttpBindingIndex::class.java)
                val tsFormat = bindingIndex.determineTimestampFormat(
                    targetShape,
                    HttpBinding.Location.DOCUMENT,
                    defaultTimestampFormat
                )
                writer.openBlock("if let $collectionName = $collectionName {", "}") {
                    writer.openBlock("for $iteratorName in $collectionName {", "}") {
                        val dateString = dateString(tsFormat, iteratorName)
                        writer.write("try $topLevelContainerName.encode($dateString)")
                    }
                }
            }
            is CollectionShape -> {
                val nestedTarget = ctx.model.expectShape(targetShape.member.target)
                if (nestedTarget.type != ShapeType.LIST || nestedTarget.type != ShapeType.SET) { //nested type is not a collection
                    writer.openBlock("if let $collectionName = $collectionName {", "}") {
                        writer.openBlock("for $iteratorName in $collectionName {", "}") {
                            writer.write("try $topLevelContainerName.encode(${iteratorName})")
                        }
                    }
                } else {
                    // nested list
                    val newLevel = level + 1
                    var nestedContainerName = "listContainer$newLevel"
                    writer.openBlock("if let $iteratorName = $iteratorName {", "}") {
                        writer.write("var $nestedContainerName = container.nestedUnkeyedContainer()")

                        writer.openBlock("for $iteratorName in $collectionName {", "}") {
                            renderEncodeList(ctx, iteratorName, nestedContainerName, nestedTarget, writer, newLevel)
                        }
                    }
                }

            }
            is MapShape -> renderEncodeMap(targetShape.value, level + 1)
            else -> writer.write("try $topLevelContainerName.encode(\$L)", collectionName)
        }
    }

    private fun renderEncodeMap(member: MemberShape, level: Int = 0) {
        val containerName = "dictContainer$level"
        writer.write("var $containerName = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .\$L)", member.memberName)
        val collectionShape = ctx.model.expectShape(member.target) as CollectionShape
        val targetShape = ctx.model.expectShape(collectionShape.member.target)
        val targetShapeName = targetShape.defaultName().toLowerCase()
        writer.openBlock("if let \$L = \$L {", member.memberName) {
            writer.openBlock("for (key,\$L) in \$L {", targetShapeName, member.memberName) {
                when(targetShape) {
                    is TimestampShape -> {
                            val tsFormat = targetShape
                                .getTrait(TimestampFormatTrait::class.java)
                                .map { it.format }
                                .orElse(defaultTimestampFormat)
                            val dateString = dateString(tsFormat, targetShapeName)
                            writer.write("try $containerName.encode($dateString, forKey: Key(stringValue: key))")
                    }
                    is CollectionShape -> {
                        val nestedTarget = ctx.model.expectShape(targetShape.member.target)
                        renderEncodeList(ctx, targetShapeName, containerName, nestedTarget, writer, level+1)
                    }
                    is MapShape -> renderEncodeMap(targetShape.value, level+1)
                    else -> writer.write("try $containerName.encode($targetShapeName, forKey: Key(stringValue: key))")
                }
            }.closeBlock("}")
        }.closeBlock("}")
    }
}