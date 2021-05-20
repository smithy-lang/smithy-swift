package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.aws.traits.protocols.AwsQueryTrait
import software.amazon.smithy.aws.traits.protocols.RestXmlTrait
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.awsquery.StructEncodeFormURLGenerator
import software.amazon.smithy.swift.codegen.integration.serde.json.StructEncodeGenerator
import software.amazon.smithy.swift.codegen.integration.serde.json.StructEncodeXMLGenerator

//Need to move this to aws-sdk-swift
class StructEncodeGeneratorStrategy(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val shapeContainingMembers: Shape,
    private val shapeMetaData: Map<String, Any>,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) {
    var generator: MemberShapeEncodeGeneratable? = null

    fun render() {
        generator = when (ctx.protocol) {
            RestXmlTrait.ID -> StructEncodeXMLGenerator(ctx, shapeContainingMembers, members, writer, defaultTimestampFormat)
            //todo this will be moved to aws-sdk-swift for sure.
            AwsQueryTrait.ID -> StructEncodeFormURLGenerator(ctx, shapeContainingMembers, shapeMetaData, members, writer, defaultTimestampFormat)
            else -> StructEncodeGenerator(ctx, members, writer, defaultTimestampFormat)
        }
        generator?.render()
    }

    fun xmlNamespaces(): Set<String> {
        generator?.let {
            return when (it) {
                is StructEncodeXMLGenerator -> it.xmlNamespaces
                else -> emptySet()
            }
        } ?: run {
            return emptySet()
        }
    }
}
