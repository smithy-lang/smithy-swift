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
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.XmlFlattenedTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeEncodeGeneratable
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
        val nestedMemberName = "${nestedMemberTarget.id.name.toLowerCase()}$level"
        writer.openBlock("for $nestedMemberName in $memberName {", "}") {
            renderNestedMember(nestedMemberName, nestedMemberTarget, containerName, isKeyed, level)
        }
    }

    fun renderNestedMember(
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
            else -> {
                val forKey = if (isKeyed) ", forKey: .member" else ""
                writer.write("try $containerName.encode($nestedMemberName$forKey)")
            }
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
