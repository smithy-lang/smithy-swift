package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.traits.JsonNameTrait
import software.amazon.smithy.model.traits.XmlNameTrait
import software.amazon.smithy.swift.codegen.SwiftWriter

class DefaultCodingKeysGenerator : CodingKeysGenerator {
    override fun generateCodingKeysForMembers(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, members: List<MemberShape>) {
        val membersSortedByName: List<MemberShape> = members.sortedBy { it.memberName }
        if (membersSortedByName.isEmpty()) {
            return
        }

        writer.openBlock("enum CodingKeys: String, CodingKey {", "}") {
            for (member in membersSortedByName) {
                val originalMemberName = member.memberName
                val modifiedMemberName = ctx.symbolProvider.toMemberName(member)
                when {
                    member.hasTrait(JsonNameTrait::class.java) -> {
                        val jsonName = member.getTrait(JsonNameTrait::class.java).get().value
                        writer.write("case $modifiedMemberName = \"$jsonName\"")
                    }
                    member.hasTrait(XmlNameTrait::class.java) -> {
                        val xmlName = member.getTrait(XmlNameTrait::class.java).get().value
                        writer.write("case $modifiedMemberName = \"$xmlName\"")
                    }
                    originalMemberName == modifiedMemberName -> {
                        writer.write("case $modifiedMemberName")
                    }
                    else -> {
                        writer.write("case \$L = \$S", modifiedMemberName, originalMemberName)
                    }
                }
            }
        }
    }
}
