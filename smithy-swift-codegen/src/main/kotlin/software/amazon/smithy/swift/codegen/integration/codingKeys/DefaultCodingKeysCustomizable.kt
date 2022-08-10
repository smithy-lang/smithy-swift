package software.amazon.smithy.swift.codegen.integration.codingKeys

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class DefaultCodingKeysCustomizable: CodingKeysCustomizable {
    override fun shouldHandleMember(member: MemberShape): Boolean {
        return false
    }

    override fun handleMember(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, member: MemberShape) {

    }
}