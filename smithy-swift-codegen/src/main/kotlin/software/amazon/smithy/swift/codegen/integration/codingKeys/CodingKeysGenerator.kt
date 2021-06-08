package software.amazon.smithy.swift.codegen.integration.codingKeys

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

interface CodingKeysGenerator {
    fun generateCodingKeysForMembers(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, members: List<MemberShape>)
}
