package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.model.shapes.BlobShape
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.ShapeMetadata

class StructDecodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val members: List<MemberShape>,
    private val metadata: Map<ShapeMetadata, Any>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeDecodeXMLGenerator(ctx, writer, defaultTimestampFormat) {

    override fun render() {
        writer.openBlock("public init (from decoder: \$T) throws {", "}", SwiftTypes.Decoder) {
            if (members.isNotEmpty()) {
                renderDecodeBody()
            }
        }
    }

    private fun renderDecodeBody() {
        val containerName = "containerValues"
        if (metadata.containsKey(ShapeMetadata.OPERATION_SHAPE)) {
            val topLevelContainerName = "topLevelContainer"
            writer.write("let $topLevelContainerName = try decoder.container(keyedBy: \$N.self)", ClientRuntimeTypes.Serde.Key)

            val operationShape = metadata[ShapeMetadata.OPERATION_SHAPE] as OperationShape
            val wrappedKeyValue = operationShape.id.name + "Result"
            writer.write("let $containerName = try $topLevelContainerName.nestedContainer(keyedBy: CodingKeys.self, forKey: \$N(\"$wrappedKeyValue\"))", ClientRuntimeTypes.Serde.Key)
        } else {
            writer.write("let $containerName = try decoder.container(keyedBy: CodingKeys.self)")
        }
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

    override fun renderAssigningDecodedMember(memberName: String, decodedMemberName: String, isBoxed: Boolean) {
        writer.write("$memberName = $decodedMemberName")
    }
    override fun renderAssigningSymbol(memberName: String, symbol: String) {
        writer.write("$memberName = $symbol")
    }
    override fun renderAssigningNil(memberName: String) {
        writer.write("$memberName = nil")
    }
}
