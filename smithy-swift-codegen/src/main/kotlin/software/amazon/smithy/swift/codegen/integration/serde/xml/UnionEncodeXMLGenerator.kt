/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.SmithyXMLTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.json.MemberShapeEncodeXMLGenerator

class UnionEncodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val shapeContainingMembers: Shape,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter
) : MemberShapeEncodeXMLGenerator(ctx, writer) {
    override fun render() {
        writer.addImport(SwiftDependency.SMITHY_XML.target)
        val structSymbol = ctx.symbolProvider.toSymbol(shapeContainingMembers)
        writer.openBlock(
            "static func writingClosure(_ value: \$N?, to writer: \$N) throws {", "}",
            structSymbol,
            SmithyXMLTypes.Writer
        ) {
            writer.write("guard let value else { writer.detach(); return }")
            writer.openBlock("switch value {", "}") {
                val membersSortedByName: List<MemberShape> = members.sortedBy { it.memberName }
                membersSortedByName.forEach { member ->
                    val memberName = ctx.symbolProvider.toMemberName(member)
                    writer.write("case let .\$L(\$L):", memberName, memberName)
                    writer.indent()
                    writeMember(member, true)
                    writer.dedent()
                }
                writer.write("case let .sdkUnknown(sdkUnknown):")
                writer.indent()
                writer.write("try writer[.init(\"sdkUnknown\")].write(sdkUnknown)")
                writer.dedent()
            }
        }
    }
}
