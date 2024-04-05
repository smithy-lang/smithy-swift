/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.json.MemberShapeEncodeXMLGenerator
import software.amazon.smithy.swift.codegen.integration.serde.json.writerSymbol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.addImports
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.requestWireProtocol

class UnionEncodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val shapeContainingMembers: Shape,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter
) : MemberShapeEncodeXMLGenerator(ctx, writer) {
    override fun render() {
        writer.addImports(ctx.service.requestWireProtocol)
        val structSymbol = ctx.symbolProvider.toSymbol(shapeContainingMembers)
        writer.openBlock(
            "static func write(value: \$N?, to writer: \$N) throws {", "}",
            structSymbol,
            ctx.service.writerSymbol,
        ) {
            writer.write("guard let value else { writer.detach(); return }")
            writer.openBlock("switch value {", "}") {
                val membersSortedByName: List<MemberShape> = members.sortedBy { it.memberName }
                membersSortedByName.forEach { member ->
                    val memberName = ctx.symbolProvider.toMemberName(member)
                    writer.write("case let .\$L(\$L):", memberName, memberName)
                    writer.indent()
                    writeMember(member, true, false)
                    writer.dedent()
                }
                writer.write("case let .sdkUnknown(sdkUnknown):")
                writer.indent()
                writer.write("try writer[\"sdkUnknown\"].write(sdkUnknown)")
                writer.dedent()
            }
        }
    }
}
