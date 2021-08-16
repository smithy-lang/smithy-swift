/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.json.MemberShapeEncodeXMLGenerator

class UnionEncodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeEncodeXMLGenerator(ctx, writer, defaultTimestampFormat) {
    override fun render() {
        val containerName = "container"
        writer.openBlock("public func encode(to encoder: \$N) throws {", "}", SwiftTypes.Encoder) {
            writer.write("var $containerName = encoder.container(keyedBy: \$N.self)", ClientRuntimeTypes.Serde.Key)
            writer.openBlock("switch self {", "}") {
                val membersSortedByName: List<MemberShape> = members.sortedBy { it.memberName }
                membersSortedByName.forEach { member ->
                    val memberTarget = ctx.model.expectShape(member.target)
                    val memberName = ctx.symbolProvider.toMemberName(member)
                    writer.write("case let .\$L(\$L):", memberName, memberName)
                    writer.indent()
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
                            renderEncodeAssociatedType(member, memberTarget, containerName)
                        }
                    }
                    writer.dedent()
                }
                writer.write("case let .sdkUnknown(sdkUnknown):")
                writer.indent()
                writer.write("try container.encode(sdkUnknown, forKey: \$N(\"sdkUnknown\"))", ClientRuntimeTypes.Serde.Key)
                writer.dedent()
            }
        }
    }
}
