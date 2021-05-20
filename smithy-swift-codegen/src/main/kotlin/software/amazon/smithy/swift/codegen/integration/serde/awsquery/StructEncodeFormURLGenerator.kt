package software.amazon.smithy.swift.codegen.integration.serde.awsquery

import jdk.dynalink.Operation
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.defaultName
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.json.StructEncodeXMLGenerator

class StructEncodeFormURLGenerator(private val ctx: ProtocolGenerator.GenerationContext,
                                   private val shapeContainingMembers: Shape,
                                   private val shapeMetadata: Map<String, Any>,
                                   private val members: List<MemberShape>,
                                   private val writer: SwiftWriter,
                                   private val defaultTimestampFormat: TimestampFormatTrait.Format): StructEncodeXMLGenerator(ctx, shapeContainingMembers, members, writer, defaultTimestampFormat) {
    override fun addConstantMembers(containerName: String) {
        val operationShapeKey = "operationShape"
        val serviceVersionKey = "serviceVersion"
        if (shapeMetadata.containsKey(operationShapeKey) && shapeMetadata.containsKey(serviceVersionKey)) {
            val operationShape = shapeMetadata[operationShapeKey] as OperationShape
            val version = shapeMetadata[serviceVersionKey] as String
            writer.write("try $containerName.encode(\"${operationShape.id.name}\", forKey:Key(\"Action\"))")
            writer.write("try $containerName.encode(\"${version}\", forKey:Key(\"Version\"))")
        }
    }

    override fun renderTopLevelNamespace(containerName: String) {
    }
}