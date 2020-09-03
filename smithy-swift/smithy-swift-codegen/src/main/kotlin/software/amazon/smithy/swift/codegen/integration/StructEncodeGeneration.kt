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
                when (target.type) {
                    ShapeType.SET, ShapeType.LIST ->{
                        writer.openBlock("if let $memberName = $memberName {", "}") {
                            renderEncodeListMember(target, memberName, containerName)
                        }
                    }
                    ShapeType.MAP -> {
                        writer.openBlock("if let $memberName = $memberName {", "}") {
                            renderEncodeMapMember(target, memberName, containerName)
                        }
                    }
                    ShapeType.TIMESTAMP -> {
                        val dateExtension = encodeDateType(member)
                        writer.write("try \$L.encode($dateExtension, forKey: .\$L)", containerName, memberName)
                    }
                    else -> {
                        val rawValue = if (target.isStringShape && target.hasTrait(EnumTrait::class.java)) ".rawValue" else ""
                        writer.write("try $containerName.encode(\$1L$rawValue, forKey: .\$1L)", memberName)
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
        return ProtocolGenerator.getFormattedDateString(tsFormat, memberName, member.isOptional)
    }

    private fun renderEncodeListMember(targetShape: Shape, keyName: String, containerName: String, level: Int = 0) {
        when (targetShape) {
            is CollectionShape, is TimestampShape -> {
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
            is MapShape -> {

                renderEncodeList(ctx, keyName, containerName, targetShape, level)
            }
            else -> {
                val rawValue = if (targetShape.isStringShape && targetShape.hasTrait(EnumTrait::class.java)) ".rawValue" else ""
                writer.write("try $containerName.encode(\$1L$rawValue)", keyName)
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
        val iteratorName = "${targetShape.defaultName().toLowerCase()}${level}"
        writer.openBlock("for $iteratorName in $collectionName {", "}") {
            when (targetShape) {
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
                is CollectionShape -> {
                    val nestedTarget = ctx.model.expectShape(targetShape.member.target)
                   renderEncodeListMember(nestedTarget, iteratorName, topLevelContainerName, level+1)

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
                else ->{
                    val rawValue = if (targetShape.isStringShape && targetShape.hasTrait(EnumTrait::class.java)) ".rawValue" else ""
                    writer.write("try $topLevelContainerName.encode(\$L$rawValue)", collectionName)
                }
            }
        }
    }

    private fun renderEncodeMapMember(valueTargetShape: Shape, keyName: String, containerName: String, level: Int = 0) {
        when (valueTargetShape) {
            is TimestampShape -> {
                val bindingIndex = ctx.model.getKnowledge(HttpBindingIndex::class.java)
                val tsFormat = bindingIndex.determineTimestampFormat(
                    valueTargetShape,
                    HttpBinding.Location.DOCUMENT,
                    defaultTimestampFormat
                )

                val dateString = ProtocolGenerator.getFormattedDateString(tsFormat, keyName, valueTargetShape.hasTrait(BoxTrait::class.java))
                writer.write("try $containerName.encode($dateString, forKey: Key(stringValue: key${level-1}))")
            }
            is CollectionShape -> {
                val topLevelContainerName = "${keyName}Container"
                writer.write("var \$L = $containerName.nestedContainer(keyedBy: Key.self)", topLevelContainerName)
                renderEncodeMap(ctx, keyName, topLevelContainerName, valueTargetShape, level)
            }
            is MapShape -> {
                val topLevelContainerName = "${keyName}Container"
                writer.write(
                    "var \$L = $containerName.nestedContainer(keyedBy: Key.self, forKey: .\$L)",
                    topLevelContainerName,
                    keyName
                )
                renderEncodeMap(ctx, keyName, topLevelContainerName, valueTargetShape, level)
            }
            else -> {
                val rawValue = if (valueTargetShape.isStringShape && valueTargetShape.hasTrait(EnumTrait::class.java)) ".rawValue" else ""
                if (level == 0) {
                    writer.write("try $containerName.encode(\$1L$rawValue, forKey: .\$1L)", keyName)
                }
                else {
                    writer.write("try $containerName.encode(\$1L$rawValue, forKey: Key(stringValue: key${level-1}))", keyName)
                }
            }
        }
    }

    private fun renderEncodeMap(
        ctx: ProtocolGenerator.GenerationContext,
        mapName: String,
        topLevelContainerName: String,
        targetShape: Shape,
        level: Int = 0
    ) {
        val valueIterator = "${targetShape.defaultName().toLowerCase()}${level}"

        writer.openBlock("for (key$level, $valueIterator) in $mapName {", "}") {
            when (targetShape) {
                is TimestampShape -> {
                    val tsFormat = targetShape
                        .getTrait(TimestampFormatTrait::class.java)
                        .map { it.format }
                        .orElse(defaultTimestampFormat)
                    val dateString = ProtocolGenerator.getFormattedDateString(tsFormat, valueIterator, targetShape.hasTrait(BoxTrait::class.java))
                    writer.write("try $topLevelContainerName.encode($dateString, forKey: Key(stringValue: key$level))")
                }
                is CollectionShape -> {
                    val nestedTarget = ctx.model.expectShape(targetShape.member.target)
                    renderEncodeListMember(
                        nestedTarget,
                        valueIterator,
                        topLevelContainerName,
                        level + 1
                    )
                }
                is MapShape -> {
                    val nestedTarget = ctx.model.expectShape(targetShape.value.target)
                    renderEncodeMapMember(
                        nestedTarget,
                        valueIterator,
                        topLevelContainerName,
                        level + 1
                    )
                }
                else -> {
                    val rawValue = if (targetShape.isStringShape && targetShape.hasTrait(EnumTrait::class.java)) ".rawValue" else ""
                    writer.write("try $topLevelContainerName.encode($valueIterator$rawValue, forKey: Key(stringValue: key$level))")
                }
            }
        }

    }
}