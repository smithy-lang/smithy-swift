/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.model.shapes.BlobShape
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.removeSurroundingBackticks

class UnionDecodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeDecodeXMLGenerator(ctx, writer, defaultTimestampFormat) {
    override fun render() {
        val containerName = "containerValues"
        writer.openBlock("public init (from decoder: \$N) throws {", "}", SwiftTypes.Decoder) {
            writer.write("let \$L = try decoder.container(keyedBy: CodingKeys.self)", containerName)
            writer.write("let key = \$L.allKeys.first", containerName)
            writer.openBlock("switch key {", "}") {
                members.forEach { member ->
                    val memberTarget = ctx.model.expectShape(member.target)
                    val memberName = ctx.symbolProvider.toMemberName(member)
                    writer.write("case .\$L:", memberName)
                    writer.indent()
                    when (memberTarget) {
                        is CollectionShape -> {
                            renderListMember(member, memberTarget, containerName, true)
                        }
                        is MapShape -> {
                            renderMapMember(member, memberTarget, containerName, true)
                        }
                        is TimestampShape -> {
                            renderTimestampMember(member, memberTarget, containerName, true)
                        }
                        is BlobShape -> {
                            renderBlobMember(member, memberTarget, containerName, true)
                        }
                        else -> {
                            renderScalarMember(member, memberTarget, containerName, isUnion = true)
                        }
                    }
                    writer.dedent()
                }
                writer.write("default:")
                writer.indent()
                writer.write("self = .sdkUnknown(\"\")")
                writer.dedent()
            }
        }
    }

    override fun renderAssigningDecodedMember(memberName: String, decodedMemberName: String, isBoxed: Boolean) {
        val member = memberName.removeSurroundingBackticks()
        if (isBoxed) {
            writer.write("self = .$member($decodedMemberName.value)")
        } else {
            writer.write("self = .$member($decodedMemberName)")
        }
    }

    override fun renderAssigningSymbol(memberName: String, symbol: String) {
        val member = memberName.removeSurroundingBackticks()
        writer.write("self = .$member($symbol)")
    }

    override fun renderAssigningNil(memberName: String) {
        writer.write("//No-op")
    }
}
