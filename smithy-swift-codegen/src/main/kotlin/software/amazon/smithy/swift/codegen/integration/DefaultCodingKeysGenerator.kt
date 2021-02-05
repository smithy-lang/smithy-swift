package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.swift.codegen.SwiftWriter

class DefaultCodingKeysGenerator : CodingKeysGenerator {
    override fun generateCodingKeysForMembers(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, members: List<MemberShape>) {
        val membersSortedByName: List<MemberShape> = members.sortedBy { it.memberName }
        writer.openBlock("private enum CodingKeys: String, CodingKey {", "}") {
            for (member in membersSortedByName) {
                val originalMemberName = member.memberName
                val modifiedMemberName = ctx.symbolProvider.toMemberName(member)

                /* If we have modified the member name to make it idiomatic to the language
                   like handling reserved keyword with appending an underscore or lowercasing the first letter,
                   we need to change the coding key accordingly so that during encoding and decoding, the modified member
                   name is transformed back to original name before it hits the service.
                 */
                if (originalMemberName == modifiedMemberName) {
                    writer.write("case \$L", modifiedMemberName)
                } else {
                    writer.write("case \$L = \$S", modifiedMemberName, originalMemberName)
                }
            }
        }
    }
}
