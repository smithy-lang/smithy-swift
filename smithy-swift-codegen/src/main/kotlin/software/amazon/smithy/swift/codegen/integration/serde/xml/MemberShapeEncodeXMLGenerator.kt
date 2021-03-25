/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration.serde.json

import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.XmlFlattenedTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeEncodeGeneratable
import software.amazon.smithy.swift.codegen.integration.serde.TimeStampFormat.Companion.determineTimestampFormat
import software.amazon.smithy.swift.codegen.integration.serde.getDefaultValueOfShapeType
import software.amazon.smithy.swift.codegen.isBoxed

abstract class MemberShapeEncodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeEncodeGeneratable {

    private val primitiveSymbols: MutableSet<ShapeType> = hashSetOf(
        ShapeType.INTEGER, ShapeType.BYTE, ShapeType.SHORT,
        ShapeType.LONG, ShapeType.FLOAT, ShapeType.DOUBLE, ShapeType.BOOLEAN
    )

    fun renderListMember(
        member: MemberShape,
        memberTarget: CollectionShape,
        containerName: String
    ) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val nestedContainer = "${memberName}Container"
        writer.openBlock("if let $memberName = $memberName {", "}") {
            if (member.hasTrait(XmlFlattenedTrait::class.java)) {
                writer.write("var $nestedContainer = $containerName.nestedUnkeyedContainer(forKey: .$memberName)")
                renderListMemberItems(memberName, memberTarget, nestedContainer, false)
            } else {
                writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .$memberName)")
                renderListMemberItems(memberName, memberTarget, nestedContainer, true)
            }
        }
    }

    private fun renderListMemberItems(
        memberName: String,
        memberTarget: CollectionShape,
        containerName: String,
        isKeyed: Boolean,
        level: Int = 0
    ) {
        val nestedMemberTarget = ctx.model.expectShape(memberTarget.member.target)
        val nestedMember = memberTarget.member
        val nestedMemberName = "${nestedMemberTarget.id.name.toLowerCase()}$level"
        writer.openBlock("for $nestedMemberName in $memberName {", "}") {
            renderNestedMember(nestedMember, nestedMemberName, nestedMemberTarget, containerName, isKeyed, level)
        }
    }

    fun renderMapMember(member: MemberShape, memberTarget: MapShape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val memberNameUnquoted = memberName.removeSurrounding("`", "`")
        val nestedContainer = "${memberNameUnquoted}Container"

        val nestedKeyTarget = ctx.model.expectShape(memberTarget.key.target)
        val nestedValueTarget = ctx.model.expectShape(memberTarget.value.target)
        val nestedKeySymbol = ctx.symbolProvider.toSymbol(nestedKeyTarget)
        val nestedValueSymbol = ctx.symbolProvider.toSymbol(nestedValueTarget)

        writer.openBlock("if let $memberName = $memberName {", "}") {
            writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: MapEntry<$nestedKeySymbol, $nestedValueSymbol>.CodingKeys.self, forKey: .$memberNameUnquoted)")
            renderMapMemberItem(memberName, memberTarget, nestedContainer)
        }
    }

    private fun renderMapMemberItem(memberName: String, mapShape: MapShape, containerName: String, level: Int = 0) {
        val keyTargetShape = ctx.model.expectShape(mapShape.key.target)
        val valueTargetShape = ctx.model.expectShape(mapShape.value.target)

        val keyTargetShapeSymbol = ctx.symbolProvider.toSymbol(keyTargetShape)
        val valueTargetShapeSymbol = ctx.symbolProvider.toSymbol(valueTargetShape)

        val nestedKeyName = "${keyTargetShape.id.name.toLowerCase()}$level"
        val nestedValueName = "${valueTargetShape.id.name.toLowerCase()}$level"
        writer.openBlock("for ($nestedKeyName, $nestedValueName) in $memberName {", "}") {
            when (valueTargetShape) {
                is MapShape -> {
                    renderNestedMapEntryKeyValue(nestedKeyName, nestedValueName, valueTargetShape, containerName, level)
                }
                is CollectionShape -> {
                    throw Exception("nested collections not supported (yet)")
                }
                else -> {
                    writer.write("var entry = $containerName.nestedContainer(keyedBy: MapKeyValue<$keyTargetShapeSymbol, $valueTargetShapeSymbol>.CodingKeys.self, forKey: .entry)")
                    writer.write("try entry.encode($nestedKeyName, forKey: .key)")
                    writer.write("try entry.encode($nestedValueName, forKey: .value)")
                }
            }
        }
    }
    private fun renderNestedMapEntryKeyValue(keyName: String, valueName: String, mapShape: MapShape, containerName: String, level: Int) {
        val keyTargetShape = ctx.model.expectShape(mapShape.key.target)
        val valueTargetShape = ctx.model.expectShape(mapShape.value.target)

        val keyTargetShapeSymbol = ctx.symbolProvider.toSymbol(keyTargetShape)
        val valueTargetShapeSymbol = ctx.symbolProvider.toSymbol(valueTargetShape)

        val nestedContainer = "nestedMapEntryContainer$level"
        writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: MapKeyValue<$keyTargetShapeSymbol, $valueTargetShapeSymbol>.CodingKeys.self, forKey: .entry)")
        writer.openBlock("if let $valueName = $valueName {", "}") {
            writer.write("try $nestedContainer.encode($keyName, forKey: .key)")
            val nextContainer = "nestedMapEntryContainer${level + 1}"
            writer.write("var $nextContainer = $nestedContainer.nestedContainer(keyedBy: MapEntry<$keyTargetShapeSymbol, $valueTargetShapeSymbol>.CodingKeys.self, forKey: .value)")
            renderMapMemberItem(valueName, mapShape, nextContainer, level + 1)
        }
    }

    fun renderNestedMember(
        nestedMember: MemberShape,
        nestedMemberName: String,
        nestedMemberTarget: Shape,
        containerName: String,
        isKeyed: Boolean,
        level: Int = 0
    ) {
        when (nestedMemberTarget) {
            is CollectionShape -> {
                var nestedContainerName = "${nestedMemberName}Container$level"
                val isBoxed = ctx.symbolProvider.toSymbol(nestedMemberTarget).isBoxed()
                if (isBoxed) {
                    writer.openBlock("if let $nestedMemberName = $nestedMemberName {", "}") {
                        if (isKeyed) {
                            writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .member)")
                        } else {
                            val containerForUnkeyed = "${nestedMemberName}ContainerForUnkeyed$level"
                            writer.write("var $containerForUnkeyed = $containerName.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self)")
                            writer.write("var $nestedContainerName = $containerForUnkeyed.nestedUnkeyedContainer(forKey: .member)")
                        }
                        renderListMemberItems(nestedMemberName, nestedMemberTarget, nestedContainerName, isKeyed, level + 1)
                    }
                }
            }
            is MapShape -> {
                throw Exception("Maps not supported yet")
            }
            is TimestampShape -> {
                val forKey = if (isKeyed) ", forKey: .member" else ""
                val format = determineTimestampFormat(nestedMember, defaultTimestampFormat)
                val encodeValue = "TimestampWrapper($nestedMemberName, format: .$format)$forKey"
                writer.write("try $containerName.encode($encodeValue)")
            }
            else -> {
                val forKey = if (isKeyed) ", forKey: .member" else ""
                writer.write("try $containerName.encode($nestedMemberName$forKey)")
            }
        }
    }

    fun renderTimestampMember(member: MemberShape, memberTarget: TimestampShape, containerName: String, nestedMemberName: String? = null) {
        val symbol = ctx.symbolProvider.toSymbol(memberTarget)
        val memberName = nestedMemberName ?: ctx.symbolProvider.toMemberName(member)
        val format = determineTimestampFormat(member, defaultTimestampFormat)
        val isBoxed = symbol.isBoxed()
        val encodeLine = "try $containerName.encode(TimestampWrapper($memberName, format: .$format), forKey: .$memberName)"
        if (isBoxed) {
            writer.openBlock("if let $memberName = $memberName {", "}") {
                writer.write(encodeLine)
            }
        } else {
            writer.write(encodeLine)
        }
    }

    fun renderScalarMember(member: MemberShape, memberTarget: Shape, containerName: String) {
        val symbol = ctx.symbolProvider.toSymbol(memberTarget)
        val memberName = ctx.symbolProvider.toMemberName(member)
        val isBoxed = symbol.isBoxed()
        if (isBoxed) {
            writer.openBlock("if let $memberName = $memberName {", "}") {
                writer.write("try $containerName.encode($memberName, forKey: .$memberName)")
            }
        } else {
            if (primitiveSymbols.contains(memberTarget.type)) {
                val defaultValue = getDefaultValueOfShapeType(memberTarget.type)
                writer.openBlock("if $memberName != $defaultValue {", "}") {
                    writer.write("try $containerName.encode($memberName, forKey: .$memberName)")
                }
            } else {
                writer.write("try $containerName.encode($memberName, forKey: .$memberName)")
            }
        }
    }
}
