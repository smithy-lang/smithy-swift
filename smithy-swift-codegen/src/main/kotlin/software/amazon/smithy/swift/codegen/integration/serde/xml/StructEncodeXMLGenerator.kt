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
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.xml.trait.XMLNamespaceTraitGenerator
import software.amazon.smithy.swift.codegen.model.isBoxed

class StructEncodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val shapeContainingMembers: Shape,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeEncodeXMLGenerator(ctx, writer, defaultTimestampFormat) {

    override fun render() {
        writer.addImport(SwiftDependency.XML_RUNTIME.target)
        writer.openBlock("public func encode(to encoder: \$N) throws {", "}", SwiftTypes.Encoder) {
            if (members.isNotEmpty()) {
                renderEncodeBody()
            }
        }
    }

    private fun renderEncodeBody() {
        val containerName = "container"
        writer.write("var $containerName = encoder.container(keyedBy: \$N.self)", ClientRuntimeTypes.Serde.Key)
        renderTopLevelNamespace(containerName)

        val membersSortedByName: List<MemberShape> = members.sortedBy { it.memberName }
        membersSortedByName.forEach { member ->
            renderSingleMember(member, containerName)
        }
    }
    private fun renderTopLevelNamespace(containerName: String) {
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
        val memberName = ctx.symbolProvider.toMemberName(member)

        when (memberTarget) {
            is CollectionShape -> {
                writer.openBlock("if let $memberName = $memberName {", "}") {
                    renderListMember(member, memberTarget, containerName)
                }
            }
            is MapShape -> {
                writer.openBlock("if let $memberName = $memberName {", "}") {
                    renderMapMember(member, memberTarget, containerName)
                }
            }
            is TimestampShape -> {
                val symbol = ctx.symbolProvider.toSymbol(memberTarget)
                val isBoxed = symbol.isBoxed()
                if (isBoxed) {
                    writer.openBlock("if let $memberName = $memberName {", "}") {
                        renderTimestampMember(member, memberTarget, containerName)
                    }
                } else {
                    renderTimestampMember(member, memberTarget, containerName)
                }
            }
            else -> {
                renderScalarMember(member, memberTarget, containerName)
            }
        }
    }
}
