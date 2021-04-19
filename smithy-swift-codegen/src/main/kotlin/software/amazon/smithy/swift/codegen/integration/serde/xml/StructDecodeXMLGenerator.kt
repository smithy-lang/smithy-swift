package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.model.shapes.BlobShape
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class StructDecodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeDecodeXMLGenerator(ctx, writer, defaultTimestampFormat) {

    override fun render() {
        writer.openBlock("public init (from decoder: Decoder) throws {", "}") {
            if (members.isNotEmpty()) {
                renderDecodeBody()
            }
        }
    }

    private fun renderDecodeBody() {
        val containerName = "containerValues"
        writer.write("let $containerName = try decoder.container(keyedBy: CodingKeys.self)")
        members.forEach { member ->
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
                renderMapMember(member, memberTarget, containerName)
            }
            is TimestampShape -> {
                renderTimestampMember(member, memberTarget, containerName)
            }
            is BlobShape -> {
                renderBlobMember(member, memberTarget, containerName)
            }
            else -> {
                renderScalarMember(member, memberTarget, containerName)
            }
        }
    }

    override fun renderAssigningDecodedMember(topLevelMemberName: String, decodedMemberName: String, isBoxed: Boolean) {
        writer.write("$topLevelMemberName = $decodedMemberName")
    }
}
