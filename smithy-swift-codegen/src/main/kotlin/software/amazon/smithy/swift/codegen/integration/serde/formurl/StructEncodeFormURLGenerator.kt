package software.amazon.smithy.swift.codegen.integration.serde.formurl

import software.amazon.smithy.model.shapes.BlobShape
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.ShapeMetadata

class StructEncodeFormURLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val customizations: FormURLEncodeCustomizable,
    private val shapeContainingMembers: Shape,
    private val shapeMetadata: Map<ShapeMetadata, Any>,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeEncodeFormURLGenerator(ctx, customizations, writer, defaultTimestampFormat) {
    override fun render() {
        writer.openBlock("public func encode(to encoder: Encoder) throws {", "}") {
            val containerName = "container"
            renderEncodeBody(containerName)
            addConstantMembers(containerName)
        }
    }

    private fun renderEncodeBody(containerName: String) {
        writer.write("var $containerName = encoder.container(keyedBy: Key.self)")

        val membersSortedByName: List<MemberShape> = members.sortedBy { it.memberName }
        membersSortedByName.forEach { member ->
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

    // TODO: Make this pluggable so that this code can exist in aws-sdk-swift
    private fun addConstantMembers(containerName: String) {
        if (shapeMetadata.containsKey(ShapeMetadata.OPERATION_SHAPE) && shapeMetadata.containsKey(ShapeMetadata.SERVICE_VERSION)) {
            val operationShape = shapeMetadata[ShapeMetadata.OPERATION_SHAPE] as OperationShape
            val version = shapeMetadata[ShapeMetadata.SERVICE_VERSION] as String
            writer.write("try $containerName.encode(\"${operationShape.id.name}\", forKey:Key(\"Action\"))")
            writer.write("try $containerName.encode(\"${version}\", forKey:Key(\"Version\"))")
        }
    }
}
