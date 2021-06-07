package software.amazon.smithy.swift.codegen.integration.codingKeys

import software.amazon.smithy.aws.traits.protocols.Ec2QueryNameTrait
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.traits.XmlNameTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.formurl.trait.Ec2QueryNameTraitGenerator
import software.amazon.smithy.swift.codegen.model.hasTrait

class CodingKeysCustomizationEc2QueryName : CodingKeysCustomizable {
    override fun shouldHandleMember(member: MemberShape): Boolean {
        return member.hasTrait<XmlNameTrait>() || member.hasTrait<Ec2QueryNameTrait>()
    }

    override fun handleMember(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, member: MemberShape) {
        val xmlName = Ec2QueryNameTraitGenerator.construct(member, member.memberName)
        val modifiedMemberName = ctx.symbolProvider.toMemberName(member)
        writer.write("case $modifiedMemberName = \"$xmlName\"")
    }
}
