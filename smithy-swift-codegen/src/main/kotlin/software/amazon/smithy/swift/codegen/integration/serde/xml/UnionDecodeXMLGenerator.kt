/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.SmithyReadWriteTypes
import software.amazon.smithy.swift.codegen.SmithyXMLTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeDecodeGeneratable

class UnionDecodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val shapeContainingMembers: Shape,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
) : MemberShapeDecodeGeneratable {
    private val memberGenerator = MemberShapeDecodeXMLGenerator(ctx, writer, shapeContainingMembers)
    override fun render() {
        writer.addImport(SwiftDependency.SMITHY_XML.target)
        writer.addImport(SwiftDependency.SMITHY_READ_WRITE.target)
        val symbol = ctx.symbolProvider.toSymbol(shapeContainingMembers)
        writer.openBlock(
            "static var readingClosure: \$N<\$N, \$N> {", "}",
            SmithyReadWriteTypes.ReadingClosure,
            symbol,
            SmithyXMLTypes.Reader,
        ) {
            writer.openBlock("return { reader in", "}") {
                writer.write("guard reader.content != nil else { return nil }")
                writer.write("let name = reader.children.first?.nodeInfo.name")
                writer.openBlock("switch name {", "}") {
                    members.forEach {
                        writer.write("case \$S:", it.memberName)
                        writer.indent()
                        memberGenerator.render(it)
                        writer.dedent()
                    }
                    writer.write("default:")
                    writer.indent()
                    writer.write("return .sdkUnknown(name ?? \"\")")
                    writer.dedent()
                }
            }
        }
    }
}
