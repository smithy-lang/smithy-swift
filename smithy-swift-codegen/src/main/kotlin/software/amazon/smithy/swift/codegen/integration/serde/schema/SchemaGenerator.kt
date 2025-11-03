package software.amazon.smithy.swift.codegen.integration.serde.schema

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTypes
import kotlin.jvm.optionals.getOrNull

class SchemaGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter,
) {
    fun renderSchema(shape: Shape) {
        writer.writeInline("let \$L = ", shape.schemaVar(writer))
        renderSchemaStruct(shape)
        writer.unwrite(",\n")
        writer.write("")
    }

    private fun renderSchemaStruct(shape: Shape, index: Int? = null) {
        writer.openBlock("\$N(", "),",SmithyTypes.Schema) {
            writer.write("id: \$S,", shape.id.toString())
            writer.write("type: .\$L,", shape.type)
            val relevantTraits = shape.allTraits.filter { permittedTraitIDs.contains(it.key.toString()) }
            if (relevantTraits.isNotEmpty()) {
                writer.openBlock("traits: [", "],") {
                    relevantTraits.forEach { trait ->
                        writer.write(
                            "\$S: \$L,",
                            trait.key.toString(),
                            trait.value.toNode().toSwiftNode(writer),
                        )
                    }
                    writer.unwrite(",\n")
                    writer.write("")
                }
            }
            if (shape.members().isNotEmpty()) {
                writer.openBlock("members: [", "],") {
                    shape.members().withIndex().forEach { renderSchemaStruct(it.value, it.index) }
                    writer.unwrite(",\n")
                    writer.write("")
                }
            }
            shape.id.member
                .getOrNull()
                ?.let { writer.write("memberName: \$S,", it) }
            targetShape(shape)?.let { writer.write("target: \$L,", it.schemaVar(writer)) }
            index?.let { writer.write("index: \$L,", it) }
            writer.unwrite(",\n")
            writer.write("")
        }
    }

    private fun targetShape(shape: Shape): Shape? = memberShape(shape)?.let { ctx.model.expectShape(it.target) }

    private fun memberShape(shape: Shape): MemberShape? = shape.asMemberShape().getOrNull()
}

private val permittedTraitIDs: Set<String> =
    setOf(
        "smithy.api#sparse",
        "smithy.api#enumValue",
        "smithy.api#jsonName",
        "smithy.api#required",
        "smithy.api#default",
        "smithy.api#timestampFormat",
        "smithy.api#httpPayload",
    )
