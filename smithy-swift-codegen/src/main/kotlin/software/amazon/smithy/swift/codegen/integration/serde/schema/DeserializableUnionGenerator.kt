package software.amazon.smithy.swift.codegen.integration.serde.schema

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.ShapeMetadata
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyReadWriteTypes

class DeserializableUnionGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val shapeContainingMembers: Shape,
    private val members: List<MemberShape>,
    private val metadata: Map<ShapeMetadata, Any>,
    private val writer: SwiftWriter,
) {

    fun render() {
        writer.openBlock("func deserializeMembers(serializer: any \$N) {", "}", SmithyReadWriteTypes.ShapeDeserializer) {
            writer.write("// union: \$L", shapeContainingMembers.id.toString())
            members.forEach {
                writer.write("//     \$L", it.memberName)
            }
        }
    }
}
