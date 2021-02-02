/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter

class UnionDecodeGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeDecodeGenerator(ctx, writer, defaultTimestampFormat) {
    fun render() {
        val containerName = "values"
        writer.openBlock("public init (from decoder: Decoder) throws {", "}") {
            writer.write("let \$L = try decoder.container(keyedBy: CodingKeys.self)", containerName)
            members.forEach { member ->
                val target = ctx.model.expectShape(member.target)
                val memberName = ctx.symbolProvider.toMemberName(member)
                when (target) {
                    is CollectionShape -> renderDecodeListMember(target, memberName, containerName, member)
                    is MapShape -> renderDecodeMapMember(target, memberName, containerName, member)
                    is TimestampShape -> renderDecodeForTimestamp(ctx, target, member, containerName)
                    else -> writeDecodeForPrimitive(target, member, containerName)
                }
            }
            writer.write("self = .sdkUnknown(\"\")")
        }
    }

    override fun renderAssigningDecodedMember(topLevelMember: MemberShape, decodedMemberName: String) {
        val topLevelMemberName = ctx.symbolProvider.toMemberName(topLevelMember)
        writer.openBlock("if let \$L = \$L {", "}", topLevelMemberName, decodedMemberName) {
            writer.write("self = .\$L(\$L)", topLevelMemberName, topLevelMemberName)
            writer.write("return")
        }
    }
}
