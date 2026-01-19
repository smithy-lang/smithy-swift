package software.amazon.smithy.swift.codegen.integration.serde.schema

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTypes
import kotlin.jvm.optionals.getOrNull

class SchemaGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter,
) {
    fun renderSchema(shape: Shape) {
        writer.openBlock(
            "var \$L: \$N {",
            "}",
            shape.schemaVar(writer),
            SmithyTypes.Schema,
        ) {
            renderSchemaStruct(shape)
            writer.unwrite(",\n")
            writer.write("")
        }
    }

    private fun renderSchemaStruct(
        shape: Shape,
        index: Int? = null,
    ) {
        writer.openBlock(".init(", "),") {
            writer.write(
                "id: \$L,",
                shapeID(shape.id),
            )
            writer.write("type: .\$L,", shape.type)
            val relevantTraits = shape.allTraits.filter { permittedTraitIDs.contains(it.key.toString()) }
            if (relevantTraits.isNotEmpty()) {
                writer.openBlock("traits: [", "],") {
                    relevantTraits.forEach { trait ->
                        writer.write(
                            "\$L: \$L,",
                            shapeID(trait.key),
                            trait.value.toNode().toSwiftNode(writer),
                        )
                    }
                }
            }
            if (shape.members().isNotEmpty()) {
                writer.openBlock("members: [", "],") {
                    shape.members().withIndex().forEach { renderSchemaStruct(it.value, it.index) }
                }
            }
            targetShape(shape)?.let {
                writer.write("target: \$L,", it.schemaVar(writer))
            }
            index?.let {
                writer.write("index: \$L,", it)
            }
            writer.unwrite(",\n")
            writer.write("")
        }
    }

    private fun shapeID(id: ShapeId): String =
        writer.format(
            ".init(\$S, \$S\$L)",
            id.namespace,
            id.name,
            id.member.getOrNull()?.let { writer.format(", \$S", it) } ?: "",
        )

    private fun targetShape(shape: Shape): Shape? = memberShape(shape)?.let { ctx.model.expectShape(it.target) }

    private fun memberShape(shape: Shape): MemberShape? = shape.asMemberShape().getOrNull()
}
