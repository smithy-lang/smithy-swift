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
import software.amazon.smithy.swift.codegen.customtraits.SwiftBoxTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.TimestampDecodeGenerator
import software.amazon.smithy.swift.codegen.integration.serde.TimestampHelpers
import software.amazon.smithy.swift.codegen.model.recursiveSymbol
import software.amazon.smithy.swift.codegen.removeSurroundingBackticks

class UnionDecodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeDecodeXMLGenerator(ctx, writer, defaultTimestampFormat) {
    override fun render() {
        val containerName = "containerValues"
        writer.openBlock("public init(from decoder: \$N) throws {", "}", SwiftTypes.Decoder) {
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
                            renderListMember(member, memberTarget, containerName)
                        }
                        is MapShape -> {
                            renderMapMember(member, memberTarget, containerName)
                        }
                        is TimestampShape -> {
                            renderTimestampMember(member, memberTarget, containerName)
                        }
                        is BlobShape -> {
                            renderBlobMember(member, memberTarget, containerName)
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

    override fun renderListMember(member: MemberShape, memberTarget: CollectionShape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member).removeSurrounding("`", "`")
        renderListMember(memberName, containerName, member, memberTarget)
    }

    override fun renderMapMember(member: MemberShape, memberTarget: MapShape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        renderMapMember(member, memberTarget, containerName, memberName)
    }

    override fun renderTimestampMember(member: MemberShape, memberTarget: TimestampShape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member).removeSurrounding("`", "`")
        val decodedMemberName = "${memberName}Decoded"
        val timestampFormat = TimestampHelpers.getTimestampFormat(member, memberTarget, defaultTimestampFormat)
        val codingKey = writer.format(".\$L", memberName)
        TimestampDecodeGenerator(
            decodedMemberName,
            containerName,
            codingKey,
            timestampFormat,
            false
        ).generate(writer)
        renderAssigningDecodedMember(memberName, decodedMemberName)
    }

    override fun renderBlobMember(member: MemberShape, memberTarget: BlobShape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val memberNameUnquoted = memberName.removeSurrounding("`", "`")
        var memberTargetSymbol = ctx.symbolProvider.toSymbol(memberTarget)
        if (member.hasTrait(SwiftBoxTrait::class.java)) {
            memberTargetSymbol = memberTargetSymbol.recursiveSymbol()
        }
        val decodedMemberName = "${memberName}Decoded"
        writer.write("let $decodedMemberName = try $containerName.decode(\$N.self, forKey: .$memberNameUnquoted)", memberTargetSymbol)
        renderAssigningDecodedMember(memberName, decodedMemberName)
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
