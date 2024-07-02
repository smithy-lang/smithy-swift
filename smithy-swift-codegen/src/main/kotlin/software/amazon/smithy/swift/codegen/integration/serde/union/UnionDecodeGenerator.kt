/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.union

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.JsonNameTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.member.MemberShapeDecodeGenerator
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.AWSProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.awsProtocol
import software.amazon.smithy.swift.codegen.integration.serde.struct.readerSymbol
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyReadWriteTypes

class UnionDecodeGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val shapeContainingMembers: Shape,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
) : MemberShapeDecodeGenerator(ctx, writer, shapeContainingMembers) {

    fun render() {
        val symbol = ctx.symbolProvider.toSymbol(shapeContainingMembers)
        writer.openBlock(
            "static func read(from reader: \$N) throws -> \$N {", "}",
            ctx.service.readerSymbol,
            symbol,
        ) {
            writer.openBlock(
                "guard let nodeInfo = reader.children.first(where: { \$\$0.hasContent && \$\$0.nodeInfo != \"__type\" })?.nodeInfo else {",
                "}"
            ) {
                writer.write("throw \$N.requiredValueNotPresent", SmithyReadWriteTypes.ReaderError)
            }
            writer.write("let name = \"\\(nodeInfo)\"")
            writer.openBlock("switch name {", "}") {
                members.forEach {
                    writer.write("case \$S:", memberName(it))
                    writer.indent()
                    render(it)
                    writer.dedent()
                }
                writer.write("default:")
                writer.indent()
                writer.write("return .sdkUnknown(name)")
                writer.dedent()
            }
        }
    }

    private fun memberName(member: MemberShape): String {
        if (ctx.service.awsProtocol == AWSProtocol.REST_JSON_1) {
            return member.getTrait<JsonNameTrait>()?.value ?: member.memberName
        } else {
            return member.memberName
        }
    }
}
