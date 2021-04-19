package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.removeSurroundingBackticks

class UnionDecodeXMLGenerator(private val ctx: ProtocolGenerator.GenerationContext,
private val members: List<MemberShape>,
private val writer: SwiftWriter,
private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeDecodeXMLGenerator(ctx, writer, defaultTimestampFormat)  {
    override fun render() {
        val containerName = "values"
        writer.openBlock("public init (from decoder: Decoder) throws {", "}") {
            writer.write("let \$L = try decoder.container(keyedBy: CodingKeys.self)", containerName)
            members.forEach { member ->
                val memberTarget = ctx.model.expectShape(member.target)
                when (memberTarget) {
                    is CollectionShape -> {
                        throw Exception("todo: Support collections")
                    }
                    is MapShape ->  {
                        throw Exception("todo: support maps")
                    }
                    is TimestampShape -> {
                        //renderTimestampMember(member,memberTarget, containerName)
                        throw Exception("todo: support timestamps")
                    }
                    else -> renderScalarMember(member, memberTarget, containerName)
                }

            }
            writer.write("self = .sdkUnknown(\"\")")
        }
    }

    override fun renderAssigningDecodedMember(topLevelMemberName: String, decodedMemberName: String, isBoxed: Boolean) {
        val member = topLevelMemberName.removeSurroundingBackticks()
        writer.openBlock("if let $topLevelMemberName = $decodedMemberName {", "}") {
            if (isBoxed) {
                writer.write("self = .$member($topLevelMemberName.value)")
            } else {
                writer.write("self = .$member($topLevelMemberName)")
            }
            writer.write("return")
        }
    }
}