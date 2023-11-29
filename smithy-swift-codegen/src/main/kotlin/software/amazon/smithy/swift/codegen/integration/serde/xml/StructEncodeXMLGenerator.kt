/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.json

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.SmithyXMLTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class StructEncodeXMLGenerator(
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
            writer.write(
                "guard \$L else { writer.detach(); return }",
                "value != nil".takeIf { members.isEmpty() } ?: "let value"
            )
            members.sortedBy { it.memberName }.forEach { writeMember(it, false) }
        }
    }
}
