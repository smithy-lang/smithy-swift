/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.json

import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class StructEncodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeEncodeXMLGenerator(ctx, writer, defaultTimestampFormat) {
    override fun render() {
        writer.openBlock("public func encode(to encoder: Encoder) throws {", "}") {
            if (members.isNotEmpty()) {
                renderEncodeBody()
            }
        }
    }

    private fun renderEncodeBody() {
        val containerName = "container"
        writer.write("var $containerName = encoder.container(keyedBy: CodingKeys.self)")
        val membersSortedByName: List<MemberShape> = members.sortedBy { it.memberName }
        membersSortedByName.forEach { member ->
            renderSingleMember(member, containerName)
        }
    }

    private fun renderSingleMember(member: MemberShape, containerName: String) {
        val memberTarget = ctx.model.expectShape(member.target)
        when (memberTarget) {
            is CollectionShape -> {
                renderListMember(member, memberTarget, containerName)
            }
            is MapShape -> {
                throw Exception("MapShape is not supported yet")
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
