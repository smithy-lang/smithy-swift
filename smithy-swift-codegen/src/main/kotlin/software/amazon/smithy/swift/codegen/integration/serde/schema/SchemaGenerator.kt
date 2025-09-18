package software.amazon.smithy.swift.codegen.integration.serde.schema

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.traits.DefaultTrait
import software.amazon.smithy.model.traits.ErrorTrait
import software.amazon.smithy.model.traits.SparseTrait
import software.amazon.smithy.model.traits.StreamingTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.isInHttpBody
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.isEnum
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyReadWriteTypes
import kotlin.jvm.optionals.getOrNull

class SchemaGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter,
) {
    fun renderSchema(shape: Shape) {
        writer.openBlock(
            "var \$L: \$N<\$N> {",
            "}",
            shape.schemaVar(writer),
            SmithyReadWriteTypes.Schema,
            ctx.symbolProvider.toSymbol(shape),
        ) {
            renderSchemaStruct(shape)
        }
    }

    private fun renderSchemaStruct(shape: Shape) {
        val shapeSymbol = ctx.symbolProvider.toSymbol(shape)
        writer.openBlock(
            "\$N<\$N>(",
            ")",
            SmithyReadWriteTypes.Schema,
            shapeSymbol,
        ) {
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
            if (shape.type == ShapeType.STRUCTURE) {
                writer.write("factory: { .init() },")
            } else if (shape.type == ShapeType.UNION) {
                writer.write("factory: { .sdkUnknown(\"\") },")
            }
            if (shape.members().isNotEmpty() && !shape.isEnum && !shape.isIntEnumShape) {
                writer.openBlock("members: [", "],") {
                    shape
                        .members()
                        .filter { it.isInHttpBody() }
                        .filter { !ctx.model.expectShape(it.target).hasTrait<StreamingTrait>() }
                        .forEach { member ->
                            writer.openBlock(".init(member:", "),") {
                                writer.openBlock(
                                    "\$N<\$N>.Member<\$N>(",
                                    ")",
                                    SmithyReadWriteTypes.Schema,
                                    shapeSymbol,
                                    ctx.symbolProvider.toSymbol(ctx.model.expectShape(member.target)),
                                ) {
                                    writer.write("memberSchema: { \$L },", member.schemaVar(writer))
                                    writeSetterGetter(writer, shape, member)
                                    writer.unwrite(",\n")
                                    writer.write("")
                                }
                            }
                        }
                    writer.unwrite(",\n")
                    writer.write("")
                }
            }
            targetShape(shape)?.let { writer.write("targetSchema: { \$L },", it.schemaVar(writer)) }
            shape.id.member
                .getOrNull()
                ?.let { writer.write("memberName: \$S,", it) }
            memberShape(shape)?.let { writer.write("containerType: .\$L,", ctx.model.expectShape(it.container).type) }
            writer.unwrite(",\n")
            writer.write("")
        }
    }

    private fun writeSetterGetter(
        writer: SwiftWriter,
        shape: Shape,
        member: MemberShape,
    ) {
        val target = ctx.model.expectShape(member.target)
        val readMethodName = target.readMethodName
        val memberIsRequired =
            member.isRequired ||
                (member.hasTrait<DefaultTrait>() || target.hasTrait<DefaultTrait>()) ||
                (shape.isMapShape && member.memberName == "value" && !shape.hasTrait<SparseTrait>()) ||
                (shape.isListShape && !shape.hasTrait<SparseTrait>()) ||
                shape.isUnionShape
        val readMethodExtension = "NonNull".takeIf { memberIsRequired } ?: ""
        when (shape.type) {
            ShapeType.STRUCTURE -> {
                val path = "properties.".takeIf { shape.hasTrait<ErrorTrait>() } ?: ""
                writer.write(
                    "readBlock: { value, _, reader in value.\$L\$L = try reader.\$L\$L(schema: \$L) },",
                    path,
                    ctx.symbolProvider.toMemberName(member),
                    readMethodName,
                    readMethodExtension,
                    member.schemaVar(writer),
                )
            }

            ShapeType.UNION -> {
                if (member.target.toString() != "smithy.api#Unit") {
                    writer.write(
                        "readBlock: { value, _, reader in try reader.\$L(schema: \$L).map { value = .\$L(\$\$0) } },",
                        readMethodName,
                        member.schemaVar(writer),
                        ctx.symbolProvider.toMemberName(member),
                    )
                } else {
                    writer.write(
                        "readBlock: { value, _, reader in try reader.\$L(schema: \$L).map { _ in value = .\$L } },",
                        readMethodName,
                        member.schemaVar(writer),
                        ctx.symbolProvider.toMemberName(member),
                    )
                }
            }

            ShapeType.SET, ShapeType.LIST -> {
                writer.write(
                    "readBlock: { value, _, reader in try value.append(reader.\$L\$L(schema: \$L)) },",
                    readMethodName,
                    readMethodExtension,
                    member.schemaVar(writer),
                )
            }

            ShapeType.MAP -> {
                if (member.memberName != "key") {
                    writer.write(
                        "readBlock: { value, key, reader in try value[key] = reader.\$L\$L(schema: \$L) },",
                        readMethodName,
                        readMethodExtension,
                        member.schemaVar(writer),
                    )
                }
            }

            else -> {}
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
