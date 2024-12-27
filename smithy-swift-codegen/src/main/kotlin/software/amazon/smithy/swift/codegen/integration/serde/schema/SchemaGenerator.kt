package software.amazon.smithy.swift.codegen.integration.serde.schema

import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.node.NodeType
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.traits.DefaultTrait
import software.amazon.smithy.model.traits.EnumValueTrait
import software.amazon.smithy.model.traits.ErrorTrait
import software.amazon.smithy.model.traits.JsonNameTrait
import software.amazon.smithy.model.traits.RequiredTrait
import software.amazon.smithy.model.traits.SparseTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyReadWriteTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTimestampsTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTypes
import kotlin.jvm.optionals.getOrNull

class SchemaGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter,
) {

    fun renderSchema(shape: Shape) {
        writer.writeInline("let \$L: \$N<\$N> = ", shape.schemaVar, SmithyReadWriteTypes.Schema, ctx.symbolProvider.toSymbol(shape))
        writer.openBlock(
            "{ \$N<\$N>(",
            ") },",
            SmithyReadWriteTypes.Schema,
            ctx.symbolProvider.toSymbol(shape),
        ) {
            writer.write("type: .\$L,", shape.type)
            if (shape.members().isNotEmpty()) {
                writer.openBlock("members: [", "],") {
                    shape.members().forEach { member ->
                        writer.openBlock(".init(member:", "),") {
                            writer.openBlock("\$N<\$N>.Member<\$N>(", ")", SmithyReadWriteTypes.Schema, ctx.symbolProvider.toSymbol(shape), ctx.symbolProvider.toSymbol(shape)) {
                                writer.write("memberSchema: \$L,", member.schemaVar)
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
            targetSchema(shape)?.let { writer.write("targetSchema: { \$L },", it.schemaVar) }
            shape.id.member.getOrNull()?.let { writer.write("memberName: \$S,", it) }
            jsonName(shape)?.let { writer.write("jsonName: \$S,", it) }
            enumValue(shape)?.let { node ->
                when (node.type) {
                    NodeType.STRING -> writer.write("enumValue: \$N(value: \$S)", SmithyTypes.StringDocument, node)
                    NodeType.NUMBER -> writer.write("enumValue: \$N(value: \$L)", SmithyTypes.IntegerDocument, node)
                    else -> throw Exception("Unsupported node type")
                }
            }
            timestampFormat(shape)?.let {
                writer.addImport(SmithyTimestampsTypes.TimestampFormat)
                writer.write("timestampFormat: .\$L,", it.swiftEnumCase)
            }
            if (isRequired(shape)) {
                writer.write("isRequired: true,")
            }
            defaultValue(shape)?.let { writer.write("defaultValue: \$L,", it) }
            writer.unwrite(",\n")
            writer.write("")
        }
        writer.unwrite(",\n")
        writer.write("()")
        writer.write("")
    }

    private fun writeSetterGetter(writer: SwiftWriter, shape: Shape, member: MemberShape) {
        val target = ctx.model.expectShape(member.target)
        val readMethodName = target.readMethodName
        val memberIsRequired = member.isRequired
                || (member.hasTrait<DefaultTrait>() || target.hasTrait<DefaultTrait>())
                || (shape.isMapShape && member.memberName == "key")
                || (shape.isMapShape && member.memberName == "value" && !shape.hasTrait<SparseTrait>())
                || (shape.isListShape && !shape.hasTrait<SparseTrait>())
        val readMethodExtension = "NonNull".takeIf { memberIsRequired || shape.isUnionShape } ?: ""
        when (shape.type) {
            ShapeType.STRUCTURE -> {
                val path = "properties.".takeIf { shape.hasTrait<ErrorTrait>() } ?: ""
                writer.write(
                    "readBlock: { \$\$0.\$L\$L = try \$\$1.\$L\$L(schema: \$L) },",
                    path,
                    ctx.symbolProvider.toMemberName(member),
                    readMethodName,
                    readMethodExtension,
                    member.schemaVar,
                )
            }
            ShapeType.UNION -> {
                writer.write(
                    "readBlock: { try \$\$0 = .\$L(\$\$1.\$LNonNull(schema: \$L)) },",
                    ctx.symbolProvider.toMemberName(member),
                    readMethodName,
                    member.schemaVar,
                )
            }
            ShapeType.SET, ShapeType.LIST -> {
                writer.write("readBlock: { try \$\$0.append(\$\$1.\$L\$L(schema: \$L)) },",
                    readMethodName,
                    readMethodExtension,
                    target.schemaVar,
                )
            }
            ShapeType.MAP -> {
                if (member.memberName != "key") {
                    writer.write(
                        "readBlock: { try \$\$0[\"value\"] = \$\$1.\$L\$L(schema: \$L) },",
                        readMethodName,
                        readMethodExtension,
                        target.schemaVar,
                    )
                }
            }
            else -> {}
        }
    }

    private fun targetSchema(shape: Shape): Shape? {
        return shape.asMemberShape().getOrNull()?.let { ctx.model.expectShape(it.target) }
    }

    private fun enumValue(shape: Shape): Node? {
        return shape.getTrait<EnumValueTrait>()?.toNode()
    }

    private fun jsonName(shape: Shape): String? {
        return shape.getTrait<JsonNameTrait>()?.value
    }

    private fun isRequired(shape: Shape): Boolean {
        return shape.hasTrait<RequiredTrait>()
    }

    private fun defaultValue(shape: Shape): String? {
        return shape.getTrait<DefaultTrait>()?.let {
            val node = it.toNode()
            when (node.type) {
                NodeType.STRING -> writer.format("\$N(value: \$S)", SmithyTypes.StringDocument, node.toString())
                NodeType.BOOLEAN -> writer.format("\$N(value: \$L)", SmithyTypes.BooleanDocument, node.toString())
                NodeType.NUMBER -> writer.format("\$N(value: \$L)", SmithyTypes.DoubleDocument, node.toString())
                NodeType.ARRAY -> writer.format("\$N(value: [])", SmithyTypes.ListDocument)
                NodeType.OBJECT -> writer.format("\$N(value: [:])", SmithyTypes.StringMapDocument)
                NodeType.NULL -> writer.format("\$N()", SmithyTypes.NullDocument)
            }
        }
    }

    private fun timestampFormat(shape: Shape): TimestampFormatTrait.Format? {
        return shape.getTrait<TimestampFormatTrait>()?.format
    }

    private val TimestampFormatTrait.Format.swiftEnumCase: String
        get() {
            return when (this) {
                TimestampFormatTrait.Format.EPOCH_SECONDS -> "epochSeconds"
                TimestampFormatTrait.Format.DATE_TIME -> "dateTime"
                TimestampFormatTrait.Format.HTTP_DATE -> "httpDate"
                else -> throw Exception("Unknown TimestampFormat")
            }
        }
}
