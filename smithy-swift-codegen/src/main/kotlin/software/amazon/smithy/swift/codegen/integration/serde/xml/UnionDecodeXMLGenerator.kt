package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.model.shapes.BlobShape
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
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
        writer.openBlock("public init (from decoder: Decoder) throws {", "}") {
            writer.write("let \$L = try decoder.container(keyedBy: CodingKeys.self)", containerName)
            members.forEach { member ->
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
            writer.write("self = .sdkUnknown(\"\")")
        }
    }

    override fun renderAssigningDecodedMember(memberName: String, decodedMemberName: String, isBoxed: Boolean) {
        val member = memberName.removeSurroundingBackticks()
        writer.openBlock("if let $memberName = $decodedMemberName {", "}") {
            if (isBoxed) {
                writer.write("self = .$member($memberName.value)")
            } else {
                writer.write("self = .$member($memberName)")
            }
            writer.write("return")
        }
    }
    override fun renderAssigningSymbol(memberName: String, symbol: String) {
        val member = memberName.removeSurroundingBackticks()
        writer.write("self = .$member($symbol)")
        writer.write("return")
    }

    override fun renderAssigningNil(memberName: String) {
        writer.write("//No-op")
    }
}
