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

import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.shapes.*
import software.amazon.smithy.model.traits.BoxTrait
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.defaultName
import java.lang.reflect.Member
import java.sql.Blob
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
 *       var nestedStringListContainer = container.nestedUnkeyedContainer(forKey: .nestedStringList)
 *       if let nestedStringList = nestedStringList {
 *         for stringlist0 in nestedStringList {
 *            try nestedStringListContainer.encode(stringlist0)
 *          }
 *       }
 *       try container.encode(stringList, forKey: .stringList)
 *       try container.encode(stringSet, forKey: .stringSet)
 *       try container.encode(structureList, forKey: .structureList)
 *       var timestampListContainer = container.nestedUnkeyedContainer(forKey: .timestampList)
 *       if let timestampList = timestampList {
 *          for timestamp0 in timestampList {
 *              try timestampListContainer.encode(timestamp0.timeIntervalSince1970)
 *          }
*        }
 *   }
 * ```
 */
class StructEncodeGeneration(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) {
    fun render() {
        val containerName = "container"
        writer.openBlock("public func encode(to encoder: Encoder) throws {", "}") {
            writer.write("var \$L = encoder.container(keyedBy: CodingKeys.self)", containerName)
            members.forEach { member ->
                val target = ctx.model.expectShape(member.target)
                val memberName = member.memberName
                when (target) {
                    is CollectionShape -> {
                        writer.openBlock("if let $memberName = $memberName {", "}") {
                            renderEncodeListMember(target, memberName, containerName)
                        }
                    }
                    is MapShape -> {
                        writer.openBlock("if let $memberName = $memberName {", "}") {
                            renderEncodeMapMember(target, memberName, containerName)
                        }
                    }
                    else -> {
                        val memberWithExtension = getShapeExtension(member, memberName)
                        writer.write("try $containerName.encode($memberWithExtension, forKey: .\$L)", memberName)
                    }
                }
            }
        }
    }

    private fun getShapeExtension(shape: Shape, memberName: String, isOptional: Boolean = true): String {
        // target shape type to deserialize is either the shape itself or member.target
        val target = when (shape) {
            is MemberShape -> ctx.model.expectShape(shape.target)
            else -> shape
        }
        return when (target) {
            is TimestampShape -> encodeDateType(shape, memberName, isOptional)
            is StringShape -> if(target.hasTrait(EnumTrait::class.java)) "$memberName.rawValue" else memberName
            is BlobShape -> "$memberName.base64EncodedString()"
            else -> memberName
        }
    }
    //timestamps are boxed by default so only pass in false if date is inside aggregate type and not labeled with box trait
    private fun encodeDateType(shape: Shape, memberName: String, isOptional: Boolean = true): String {
      //  val bindingIndex = ctx.model.getKnowledge(HttpBindingIndex::class.java)
        val tsFormat = shape
            .getTrait(TimestampFormatTrait::class.java)
            .map { it.format }
            .orElse(defaultTimestampFormat)
        return ProtocolGenerator.getFormattedDateString(tsFormat, memberName, isOptional)
    }

    private fun renderEncodeListMember(targetShape: Shape, keyName: String, containerName: String, level: Int = 0) {
        when (targetShape) {
            is CollectionShape -> {
                val topLevelContainerName = "${keyName}Container"

                if (level == 0) {
                    writer.write(
                        "var \$L = $containerName.nestedUnkeyedContainer(forKey: .\$L)",
                        topLevelContainerName,
                        keyName
                    )
                } else {
                    writer.write("var \$L = $containerName.nestedUnkeyedContainer()", topLevelContainerName)
                }
                renderEncodeList(ctx, keyName, topLevelContainerName, targetShape, level)
            }
            is MapShape -> renderEncodeList(ctx, keyName, containerName, targetShape, level)
            else -> {
                val extension = getShapeExtension(targetShape, keyName, false)
                writer.write("try $containerName.encode($extension)")
            }

        }
    }

    private fun renderEncodeList(
        ctx: ProtocolGenerator.GenerationContext,
        collectionName: String,
        topLevelContainerName: String,
        targetShape: Shape,
        level: Int = 0
    ) {
        val iteratorName = "${targetShape.defaultName().toLowerCase()}$level"
        writer.openBlock("for $iteratorName in $collectionName {", "}") {
            when (targetShape) {
                is CollectionShape -> {
                    val nestedTarget = ctx.model.expectShape(targetShape.member.target)
                    renderEncodeListMember(nestedTarget, iteratorName, topLevelContainerName, level + 1)
                }
                is MapShape -> {
                    val nestedTarget = ctx.model.expectShape(targetShape.value.target)
                    renderEncodeMapMember(
                        nestedTarget,
                        "Key(stringValue: key)",
                        topLevelContainerName,
                        level + 1
                    )
                }
                is TimestampShape -> {
                    val bindingIndex = ctx.model.getKnowledge(HttpBindingIndex::class.java)
                    val tsFormat = bindingIndex.determineTimestampFormat(
                        targetShape,
                        HttpBinding.Location.DOCUMENT,
                        defaultTimestampFormat
                    )

                    val dateString = ProtocolGenerator.getFormattedDateString(tsFormat, iteratorName, targetShape.hasTrait(BoxTrait::class.java))
                    writer.write("try $topLevelContainerName.encode($dateString)")
                }
                is BlobShape -> writer.write("try $topLevelContainerName.encode($iteratorName.base64EncodedString())")
                is StringShape -> {
                    val extension = if (targetShape.hasTrait(EnumTrait::class.java)) ".rawValue" else ""
                    writer.write("try $topLevelContainerName.encode($iteratorName$extension)")
                }
                else ->  writer.write("try $topLevelContainerName.encode(\$L)", iteratorName)


            }
        }
    }

    private fun renderEncodeMapMember(targetShape: Shape, keyName: String, containerName: String, level: Int = 0) {
        when (targetShape) {
            is CollectionShape -> {
                val topLevelContainerName = "${keyName}Container"
                writer.write("var \$L = $containerName.nestedContainer(keyedBy: Key.self)", topLevelContainerName)
                renderEncodeMap(ctx, keyName, topLevelContainerName, targetShape, level)
            }
            is MapShape -> {
                val topLevelContainerName = "${keyName}Container"
                writer.write(
                    "var \$L = $containerName.nestedContainer(keyedBy: Key.self, forKey: .\$L)",
                    topLevelContainerName,
                    keyName
                )
                renderEncodeMap(ctx, keyName, topLevelContainerName, targetShape.value, level)
            }
            else -> {
                val extension = getShapeExtension(targetShape, keyName, false)
                if (level == 0) {
                    writer.write("try $containerName.encode($extension, forKey: .\$L)", keyName)
                } else {
                    writer.write("try $containerName.encode($extension, forKey: Key(stringValue: key${level - 1}))")
                }
            }
        }
    }

    private fun renderEncodeMap(
        ctx: ProtocolGenerator.GenerationContext,
        mapName: String,
        topLevelContainerName: String,
        valueTargetShape: Shape,
        level: Int = 0
    ) {
        val valueIterator = "${valueTargetShape.defaultName().toLowerCase()}$level"
        val target = when (valueTargetShape) {
            is MemberShape -> ctx.model.expectShape(valueTargetShape.target)
            else -> valueTargetShape
        }
        writer.openBlock("for (key$level, $valueIterator) in $mapName {", "}") {
            when (target) {
                is TimestampShape -> {
                    val bindingIndex = ctx.model.getKnowledge(HttpBindingIndex::class.java)
                    val tsFormat = bindingIndex.determineTimestampFormat(
                        valueTargetShape,
                        HttpBinding.Location.DOCUMENT,
                        defaultTimestampFormat
                    )
                    val dateString = ProtocolGenerator.getFormattedDateString(tsFormat, valueIterator, target.hasTrait(BoxTrait::class.java))
                    writer.write("try $topLevelContainerName.encode($dateString, forKey: Key(stringValue: key$level))")
                }
                is CollectionShape -> {
                    val nestedTarget = ctx.model.expectShape(target.member.target)
                    renderEncodeListMember(
                        nestedTarget,
                        valueIterator,
                        topLevelContainerName,
                        level + 1
                    )
                }
                is MapShape -> {
                    val nestedTarget = ctx.model.expectShape(target.value.target)
                    renderEncodeMapMember(
                        nestedTarget,
                        valueIterator,
                        topLevelContainerName,
                        level + 1
                    )
                }
                is StringShape -> {
                    val extension = if (target.hasTrait(EnumTrait::class.java)) ".rawValue" else ""
                    writer.write("try $topLevelContainerName.encode($valueIterator$extension, forKey: Key(stringValue: key$level))")
                }
                is BlobShape -> writer.write("try $topLevelContainerName.encode($valueIterator.base64EncodedString(), forKey: Key(stringValue: key$level))")
                else -> {
                    writer.write("try $topLevelContainerName.encode($valueIterator, forKey: Key(stringValue: key$level))")
                }
            }
        }
    }
}
