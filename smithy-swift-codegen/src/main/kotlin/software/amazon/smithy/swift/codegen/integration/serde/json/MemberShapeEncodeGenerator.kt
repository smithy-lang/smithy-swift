/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration.serde.json

import software.amazon.smithy.model.shapes.BlobShape
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.BoxTrait
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.SparseTrait
import software.amazon.smithy.model.traits.StreamingTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.customtraits.SwiftBoxTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeEncodeGeneratable
import software.amazon.smithy.swift.codegen.integration.serde.getDefaultValueOfShapeType
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.isBoxed

/*
Includes functions to help render conformance to Encodable protocol for shapes
 */
abstract class MemberShapeEncodeGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeEncodeGeneratable {

    private val dictKey = "dictKey"
    /*
     Add custom extensions to be rendered to handle optional shapes and
     special types like enum, timestamp, blob
     */
    private fun getShapeExtension(shape: Shape, memberName: String, isBoxed: Boolean, isUnwrapped: Boolean = true): String {
        val isRecursiveMember = when (shape) {
            is MemberShape -> shape.hasTrait(SwiftBoxTrait::class.java)
            else -> false
        }

        // target shape type to deserialize is either the shape itself or member.target
        val target = when (shape) {
            is MemberShape -> ctx.model.expectShape(shape.target)
            else -> shape
        }
        val optional = if ((isBoxed && isUnwrapped) || !isBoxed) "" else "?"
        val memberNameOptional = "$memberName$optional"
        return when (target) {
            is TimestampShape -> encodeDateType(shape, memberName, isUnwrapped)
            is StringShape -> if (target.hasTrait<EnumTrait>()) "$memberNameOptional.rawValue" else memberName
            is BlobShape -> if (target.hasTrait<StreamingTrait>()) "$memberNameOptional.toBytes().toData()" else "$memberNameOptional.base64EncodedString()"
            else -> if (isRecursiveMember) "$memberName.value" else memberName
        }
    }

    // timestamps are boxed by default so only pass in false if date is inside aggregate type and not labeled with box trait
    private fun encodeDateType(shape: Shape, memberName: String, isUnwrapped: Boolean = true): String {
        val tsFormat = shape
            .getTrait(TimestampFormatTrait::class.java)
            .map { it.format }
            .orElse(defaultTimestampFormat)
        return ProtocolGenerator.getFormattedDateString(tsFormat, memberName, isUnwrapped)
    }

    // Render encoding of a member of list type
    fun renderEncodeListMember(
        targetShape: Shape,
        memberName: String,
        containerName: String,
        level: Int = 0
    ) {
        when (targetShape) {
            is CollectionShape -> {
                val topLevelContainerName = "${memberName}Container"

                if (level == 0) {
                    writer.write(
                        "var \$L = $containerName.nestedUnkeyedContainer(forKey: .\$L)",
                        topLevelContainerName,
                        memberName
                    )
                    renderEncodeList(ctx, memberName, topLevelContainerName, targetShape, level)
                } else {
                    writer.write("var \$L = $containerName.nestedUnkeyedContainer()", topLevelContainerName)
                    val isSparse = targetShape.hasTrait<SparseTrait>()
                    if (isSparse) {
                        writer.openBlock("if let \$L = \$L {", "}", memberName, memberName) {
                            renderEncodeList(ctx, memberName, topLevelContainerName, targetShape, level)
                        }
                    } else {
                        renderEncodeList(ctx, memberName, topLevelContainerName, targetShape, level)
                    }
                }
            }
            // this only gets called in a recursive loop where there is a map nested deeply inside a list
            is MapShape -> {
                val topLevelContainerName = "${memberName}Container"
                writer.write("var \$L = $containerName.nestedContainer(keyedBy: \$N.self)", topLevelContainerName, ClientRuntimeTypes.Serde.Key)
                val isSparse = targetShape.hasTrait<SparseTrait>()
                if (isSparse) {
                    writer.openBlock("if let \$L = \$L {", "}", memberName, memberName) {
                        renderEncodeMap(ctx, memberName, topLevelContainerName, targetShape, level)
                    }
                } else {
                    renderEncodeMap(ctx, memberName, topLevelContainerName, targetShape, level)
                }
            }
            else -> {
                val extension = getShapeExtension(targetShape, memberName, false)
                writer.write("try $containerName.encode($extension)")
            }
        }
    }

    // Iterate over and render encoding for all members of a list
    private fun renderEncodeList(
        ctx: ProtocolGenerator.GenerationContext,
        collectionName: String,
        topLevelContainerName: String,
        targetShape: Shape,
        level: Int = 0
    ) {
        val iteratorName = "${targetShape.id.name.lowercase()}$level"
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
                        "${ClientRuntimeTypes.Serde.Key}(stringValue: $dictKey)",
                        topLevelContainerName,
                        level + 1
                    )
                }
                else -> {
                    val shapeExtension = getShapeExtension(targetShape, iteratorName, targetShape.hasTrait(BoxTrait::class.java))
                    val isBoxed = ctx.symbolProvider.toSymbol(targetShape).isBoxed() && targetShape.hasTrait<SparseTrait>()
                    if (isBoxed) {
                        writer.openBlock("if let \$L = \$L {", "}", iteratorName, iteratorName) {
                            writer.write("try $topLevelContainerName.encode($shapeExtension)")
                        }
                    } else {
                        writer.write("try $topLevelContainerName.encode($shapeExtension)")
                    }
                }
            }
        }
    }

    // Render encoding of a member of Map type
    fun renderEncodeMapMember(targetShape: Shape, memberName: String, containerName: String, level: Int = 0) {
        when (targetShape) {
            is CollectionShape -> {
                val topLevelContainerName = "${memberName}Container"
                writer.write("var \$L = $containerName.nestedUnkeyedContainer(forKey: \$N($dictKey${level - 1}))", topLevelContainerName, ClientRuntimeTypes.Serde.Key)
                renderEncodeList(ctx, memberName, topLevelContainerName, targetShape, level)
            }
            is MapShape -> {
                val topLevelContainerName = "${memberName}Container"
                writer.write(
                    "var \$L = $containerName.nestedContainer(keyedBy: \$N.self, forKey: .\$L)",
                    topLevelContainerName,
                    ClientRuntimeTypes.Serde.Key,
                    memberName
                )
                renderEncodeMap(ctx, memberName, topLevelContainerName, targetShape.value, level)
            }
            else -> {
                val extension = getShapeExtension(targetShape, memberName, false)
                val isBoxed = ctx.symbolProvider.toSymbol(targetShape).isBoxed() && targetShape.hasTrait<SparseTrait>()
                val keyEnumName = if (level == 0) ".$memberName" else "${ClientRuntimeTypes.Serde.Key}(stringValue: $dictKey${level - 1})"
                if (isBoxed && level == 0) {
                    writer.openBlock("if let \$L = \$L {", "}", memberName, memberName) {
                        writer.write("try $containerName.encode($extension, forKey: \$L)", keyEnumName)
                    }
                } else {
                    writer.write("try $containerName.encode($extension, forKey: \$L)", keyEnumName)
                }
            }
        }
    }

    // Iterate over and render encoding for all members of a map
    private fun renderEncodeMap(
        ctx: ProtocolGenerator.GenerationContext,
        mapName: String,
        topLevelContainerName: String,
        valueTargetShape: Shape,
        level: Int = 0
    ) {
        val valueIterator = "${valueTargetShape.id.name.toLowerCase()}$level"
        val target = when (valueTargetShape) {
            is MemberShape -> ctx.model.expectShape(valueTargetShape.target)
            else -> valueTargetShape
        }
        writer.openBlock("for ($dictKey$level, $valueIterator) in $mapName {", "}") {
            when (target) {
                is CollectionShape -> {
                    val nestedTarget = ctx.model.expectShape(target.member.target)
                    renderEncodeMapMember(
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
                else -> {
                    val shapeExtension = getShapeExtension(valueTargetShape, valueIterator, valueTargetShape.hasTrait(BoxTrait::class.java))
                    writer.write("try $topLevelContainerName.encode($shapeExtension, forKey: \$N(stringValue: $dictKey$level))", ClientRuntimeTypes.Serde.Key)
                }
            }
        }
    }

    // Render default encoding of a member
    fun renderSimpleEncodeMember(
        target: Shape,
        member: MemberShape,
        containerName: String,
        httpPayloadTraitNotOnAnyMember: Boolean = false
    ) {
        val symbol = ctx.symbolProvider.toSymbol(target)
        val memberName = ctx.symbolProvider.toMemberName(member)
        val isBoxed = symbol.isBoxed()
        val memberWithExtension = getShapeExtension(member, memberName, isBoxed, true)
        if (isBoxed) {
            writer.openBlock("if let $memberName = $memberName {", "}") {
                writer.write("try $containerName.encode($memberWithExtension, forKey: .\$L)", memberName)
            }
        } else {
            val primitiveSymbols: MutableSet<ShapeType> = hashSetOf(
                ShapeType.INTEGER, ShapeType.BYTE, ShapeType.SHORT,
                ShapeType.LONG, ShapeType.FLOAT, ShapeType.DOUBLE, ShapeType.BOOLEAN
            )
            if (primitiveSymbols.contains(target.type)) {
                val defaultValue = getDefaultValueOfShapeType(target.type)
                writer.openBlock("if $memberName != $defaultValue {", "}") {
                    writer.write("try $containerName.encode($memberWithExtension, forKey: .\$L)", memberName)
                }
            } else
                writer.write("try $containerName.encode($memberWithExtension, forKey: .\$L)", memberName)
        }
    }

    fun renderEncodeAssociatedType(
        target: Shape,
        member: MemberShape,
        containerName: String
    ) {
        val symbol = ctx.symbolProvider.toSymbol(target)
        val memberName = ctx.symbolProvider.toMemberName(member)
        val isBoxed = symbol.isBoxed()
        val memberWithExtension = getShapeExtension(member, memberName, isBoxed, true)
        writer.write("try $containerName.encode($memberWithExtension, forKey: .\$L)", memberName)
    }
}
