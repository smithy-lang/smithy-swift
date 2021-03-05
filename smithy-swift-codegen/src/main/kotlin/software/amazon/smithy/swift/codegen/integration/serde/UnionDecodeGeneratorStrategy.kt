package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.aws.traits.protocols.RestXmlTrait
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.json.UnionDecodeGenerator

class UnionDecodeGeneratorStrategy(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) {
    fun render() {
        val generator = when (ctx.protocol) {
            // This will eventually be a xml specific struct encode generator
            RestXmlTrait.ID -> UnionDecodeGenerator(ctx, members, writer, defaultTimestampFormat)
            else -> UnionDecodeGenerator(ctx, members, writer, defaultTimestampFormat)
        }
        generator.render()
    }
}
