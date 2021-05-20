/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.json

import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.xml.trait.XMLNamespaceTraitGenerator

open class StructEncodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val shapeContainingMembers: Shape,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeEncodeXMLGenerator(ctx, writer, defaultTimestampFormat) {

    override fun render() {
        writer.openBlock("public func encode(to encoder: Encoder) throws {", "}") {
            val containerName = "container"
            writer.write("var $containerName = encoder.container(keyedBy: Key.self)")
            if (members.isNotEmpty()) {
                renderEncodeBody(containerName)
            }
            addConstantMembers(containerName)
        }
    }
    open fun addConstantMembers(containerName: String) {
    }

    private fun renderEncodeBody(containerName: String) {
        renderTopLevelNamespace(containerName)

        val membersSortedByName: List<MemberShape> = members.sortedBy { it.memberName }
        membersSortedByName.forEach { member ->
            renderSingleMember(member, containerName)
        }
    }
    open fun renderTopLevelNamespace(containerName: String) {
        val serviceNamespace = XMLNamespaceTraitGenerator.construct(ctx.service)
        val shapeContainingMembersNamespace = XMLNamespaceTraitGenerator.construct(shapeContainingMembers)
        val namespace = if (serviceNamespace != null && shapeContainingMembersNamespace == null) {
            serviceNamespace
        } else {
            shapeContainingMembersNamespace
        }

        namespace?.let {
            writer.openBlock("if encoder.codingPath.isEmpty {", "}") {
                it.render(writer, containerName)
                it.appendKey(xmlNamespaces)
            }
        }
    }

    private fun renderSingleMember(member: MemberShape, containerName: String) {
        val memberTarget = ctx.model.expectShape(member.target)
        when (memberTarget) {
            is CollectionShape -> {
                renderListMember(member, memberTarget, containerName)
            }
            is MapShape -> {
                renderMapMember(member, memberTarget, containerName)
            }
            is TimestampShape -> {
                renderTimestampMember(member, memberTarget, containerName)
            }
            else -> {
                renderScalarMember(member, memberTarget, containerName)
            }
        }
    }
}
