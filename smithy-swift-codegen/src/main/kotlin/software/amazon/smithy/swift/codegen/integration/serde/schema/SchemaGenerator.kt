package software.amazon.smithy.swift.codegen.integration.serde.schema

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.node.NodeType
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.DefaultTrait
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.ErrorTrait
import software.amazon.smithy.model.traits.JsonNameTrait
import software.amazon.smithy.model.traits.RequiredTrait
import software.amazon.smithy.model.traits.SparseTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.XmlNameTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.customtraits.NestedTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.nestedNamespaceType
import software.amazon.smithy.swift.codegen.model.toOptional
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyReadWriteTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTimestampsTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTypes
import kotlin.jvm.optionals.getOrNull

class SchemaGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter,
) {

    fun renderSchemas(shape: Shape) {
        writer.writeInline("let \$L: \$N<\$N> = ", shape.id.schemaVar(writer), schemaType(shape), swiftSymbolFor(ctx, shape))
        renderSingleSchema(shape)
        writer.unwrite(",\n")
        writer.write("()")
        writer.write("")
    }

    private fun renderSingleSchema(shape: Shape, optionalize: Boolean = false) {
        writer.openBlock(
            "{ \$N<\$N>(",
            ") },",
            schemaType(shape),
            swiftSymbolFor(ctx, shape).optionalIf(optionalize),
        ) {
//            writer.write("namespace: \$S,", shape.id.namespace)
//            writer.write("name: \$S,", shape.id.name)
            writer.write("type: .\$L,", shape.type)
            when (shape.type) {
                ShapeType.STRUCTURE, ShapeType.UNION -> {
                    if (shape.members().isNotEmpty()) {
                        writer.openBlock("members: [", "],") {
                            shape.members().forEach { member ->
                                writer.openBlock(".init(", "),") {
                                    writer.writeInline("memberSchema: ")
                                    renderSingleSchema(member)
                                    writer.write("targetSchema: { \$L },", member.target.schemaVar(writer))
                                    writeSetterGetter(ctx, writer, shape, member)
                                }
                            }
                            writer.unwrite(",\n")
                            writer.write("")
                        }
                    }
                }
                ShapeType.LIST, ShapeType.SET -> {
                    val member = shape.members().first { it.memberName == "member" }
                    val target = ctx.model.expectShape(member.target)
                    writer.writeInline("memberSchema: ")
                    renderSingleSchema(member, shape.hasTrait<SparseTrait>())
                    writer.write("targetSchema: { \$L },", target.id.schemaVar(writer))
                    writeSetterGetter(ctx, writer, shape, member)
                }
                ShapeType.MAP -> {
                    val keyMember = shape.members().first { it.memberName == "key" }
                    val keyTarget = keyMember.let { ctx.model.expectShape(it.target) }
                    val valueMember = shape.members().first { it.memberName == "value" }
                    val valueTarget = valueMember.let { ctx.model.expectShape(it.target) }
                    writer.writeInline("keyMemberSchema: ")
                    renderSingleSchema(keyMember)
                    writer.write("keyTargetSchema: { \$L },", keyTarget.id.schemaVar(writer))
                    writer.writeInline("valueMemberSchema: ")
                    renderSingleSchema(valueMember, shape.hasTrait<SparseTrait>())
                    writer.write("valueTargetSchema: { \$L },", valueTarget.id.schemaVar(writer))
                    writeSetterGetter(ctx, writer, shape, valueMember)
                }
                ShapeType.MEMBER -> {
                    shape.id.member.getOrNull()?.let { writer.write("memberName: \$S,", it) }
                    jsonName(shape)?.let { writer.write("jsonName: \$S,", it) }
                    xmlName(shape)?.let { writer.write("xmlName: \$S,", it) }
                    if (isRequired(shape)) {
                        writer.write("isRequired: true,")
                    }
                    defaultValue(shape)?.let { writer.write("defaultValue: \$L,", it) }
                }
                else -> {
                    timestampFormat(shape)?.let {
                        writer.addImport(SmithyTimestampsTypes.TimestampFormat)
                        writer.write("timestampFormat: .\$L", it.swiftEnumCase)
                    }
                    defaultValue(shape)?.let { writer.write("defaultValue: \$L,", it) }
                }
            }
            writer.unwrite(",\n")
            writer.write("")
        }
    }

    private fun schemaType(shape: Shape): Symbol {
        return when (shape.type) {
            ShapeType.STRUCTURE, ShapeType.UNION -> SmithyReadWriteTypes.StructureSchema
            ShapeType.LIST, ShapeType.SET -> SmithyReadWriteTypes.ListSchema
            ShapeType.MAP -> SmithyReadWriteTypes.MapSchema
            ShapeType.MEMBER -> SmithyReadWriteTypes.MemberSchema
            else -> SmithyReadWriteTypes.SimpleSchema
        }
    }

    private fun swiftSymbolFor(ctx: ProtocolGenerator.GenerationContext, shape: Shape): Symbol {
        return swiftSymbolWithOptionalRecursion(ctx, shape, true)
    }

    private fun swiftSymbolWithOptionalRecursion(ctx: ProtocolGenerator.GenerationContext, shape: Shape, recurse: Boolean): Symbol {
        val service = ctx.model.getShape(ctx.settings.service).get() as ServiceShape
        return when (shape.type) {
            ShapeType.STRUCTURE, ShapeType.UNION -> {
                val symbol = ctx.symbolProvider.toSymbol(shape)
                if (shape.hasTrait<NestedTrait>() && !shape.hasTrait<ErrorTrait>()) {
                    return symbol.toBuilder().namespace(service.nestedNamespaceType(ctx.symbolProvider).name, ".").build()
                } else {
                    return symbol
                }
            }
            ShapeType.LIST, ShapeType.SET -> {
                val target = shape.members()
                    .first { it.memberName == "member" }
                    ?.let { ctx.model.expectShape(it.target) }
                    ?: run { throw Exception("List / set does not have target") }
                val innerSymbol = swiftSymbolWithOptionalRecursion(ctx, target, false).optionalIf(shape.hasTrait<SparseTrait>())
                return if (recurse) {
                    innerSymbol
                } else {
                    Symbol.builder()
                        .name(writer.format("[  \$N ]", innerSymbol))
                        .build()
                }
            }
            ShapeType.MAP -> {
                val target = shape.members()
                    .first { it.memberName == "value" }
                    ?.let { ctx.model.expectShape(it.target) }
                    ?: run { throw Exception("Map does not have target") }
                val innerSymbol = swiftSymbolWithOptionalRecursion(ctx, target, false).optionalIf(shape.hasTrait<SparseTrait>())
                return if (recurse) {
                    innerSymbol
                } else {
                    Symbol.builder()
                        .name(writer.format("[Swift.String: \$N]", innerSymbol))
                        .build()
                }
            }
            ShapeType.MEMBER -> {
                val memberShape = shape as MemberShape
                val target = ctx.model.expectShape(memberShape.target)
                swiftSymbolWithOptionalRecursion(ctx, target, false)
            }
            else -> {
                ctx.symbolProvider.toSymbol(shape)
            }
        }
    }

    fun Symbol.optionalIf(isOptional: Boolean): Symbol {
        if (isOptional) {
            return this.toOptional()
        } else {
            return this
        }
    }

    private fun writeSetterGetter(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, shape: Shape, member: MemberShape) {
        val target = ctx.model.expectShape(member.target)
        val readMethodName = target.readMethodName
        val memberIsRequired = member.isRequired
                || (member.hasTrait<DefaultTrait>() || target.hasTrait<DefaultTrait>())
                || (shape.isMapShape && member.memberName == "key")
                || (shape.isMapShape && member.memberName == "value" && !shape.hasTrait<SparseTrait>())
                || (shape.isListShape && !shape.hasTrait<SparseTrait>())
        val transformMethodName = "required".takeIf { memberIsRequired || shape.isUnionShape } ?: "optional"
        when (shape.type) {
            ShapeType.STRUCTURE -> {
                val path = "properties.".takeIf { shape.hasTrait<ErrorTrait>() } ?: ""
                writer.write(
                    "readBlock: { \$\$0.\$L\$L = try \$\$1.\$L(schema: \$L) ?? \$N.\$L(\$\$2) },",
                    path,
                    ctx.symbolProvider.toMemberName(member),
                    readMethodName,
                    target.id.schemaVar(writer),
                    SmithyReadWriteTypes.DefaultValueTransformer,
                    transformMethodName,
                )
                writer.write("writeBlock: { _, _ in }")
            }
            ShapeType.UNION -> {
                writer.write("readBlock: { \$\$0 = .\$L(try \$\$1.\$L(schema: \$L) ?? \$N.\$L(\$\$2)) },", ctx.symbolProvider.toMemberName(member), readMethodName, target.id.schemaVar(writer),
                    SmithyReadWriteTypes.DefaultValueTransformer,
                    transformMethodName,
                )
                writer.write("writeBlock: { _, _ in }")
            }
            ShapeType.LIST, ShapeType.SET, ShapeType.MAP -> {
                writer.write("readBlock: { try \$\$0.\$L(schema: \$L) ?? \$N.\$L(nil) },", readMethodName, target.id.schemaVar(writer),
                    SmithyReadWriteTypes.DefaultValueTransformer,
                    transformMethodName,
                )
                writer.write("writeBlock: { _, _ in }")
            }
            else -> {}
        }
    }

    private fun jsonName(shape: Shape): String? {
        return shape.getTrait<JsonNameTrait>()?.value
    }

    private fun xmlName(shape: Shape): String? {
        return shape.getTrait<XmlNameTrait>()?.value
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

fun ShapeId.schemaVar(writer: SwiftWriter): String {
    return when (Pair(this.namespace, this.name)) {
//        Pair("smithy.api", "Unit") -> writer.format("\$N", SmithyReadWriteTypes.unitSchema)
//        Pair("smithy.api", "Boolean") -> writer.format("\$N", SmithyReadWriteTypes.booleanSchema)
//        Pair("smithy.api", "Byte") -> writer.format("\$N", SmithyReadWriteTypes.byteSchema)
//        Pair("smithy.api", "Short") -> writer.format("\$N", SmithyReadWriteTypes.shortSchema)
//        Pair("smithy.api", "Integer") -> writer.format("\$N", SmithyReadWriteTypes.integerSchema)
//        Pair("smithy.api", "Long") -> writer.format("\$N", SmithyReadWriteTypes.longSchema)
//        Pair("smithy.api", "Float") -> writer.format("\$N", SmithyReadWriteTypes.floatSchema)
//        Pair("smithy.api", "Double") -> writer.format("\$N", SmithyReadWriteTypes.doubleSchema)
//        Pair("smithy.api", "String") -> writer.format("\$N", SmithyReadWriteTypes.stringSchema)
//        Pair("smithy.api", "Document") -> writer.format("\$N", SmithyReadWriteTypes.documentSchema)
//        Pair("smithy.api", "Blob") -> writer.format("\$N", SmithyReadWriteTypes.blobSchema)
//        Pair("smithy.api", "Timestamp") -> writer.format("\$N", SmithyReadWriteTypes.timestampSchema)
        else -> {
            val namespacePortion = this.namespace.replace(".", "_")
            val memberPortion = this.member.getOrNull()?.let { "_member_$it" } ?: ""
            "${namespacePortion}__${this.name}_schema${memberPortion}"
        }
    }
}

val Shape.readMethodName: String
    get() = when (type) {
        ShapeType.BLOB -> "readBlob"
        ShapeType.BOOLEAN -> "readBoolean"
        ShapeType.STRING -> "readEnum".takeIf { hasTrait<EnumTrait>() } ?: "readString"
        ShapeType.ENUM -> "readEnum"
        ShapeType.TIMESTAMP -> "readTimestamp"
        ShapeType.BYTE -> "readByte"
        ShapeType.SHORT -> "readShort"
        ShapeType.INTEGER -> "readInteger"
        ShapeType.INT_ENUM -> "readIntEnum"
        ShapeType.LONG -> "readLong"
        ShapeType.FLOAT -> "readFloat"
        ShapeType.DOCUMENT -> "readDocument"
        ShapeType.DOUBLE -> "readDouble"
        ShapeType.BIG_DECIMAL -> "readBigDecimal"
        ShapeType.BIG_INTEGER -> "readBigInteger"
        ShapeType.LIST, ShapeType.SET -> "readList"
        ShapeType.MAP -> "readMap"
        ShapeType.STRUCTURE, ShapeType.UNION -> "readStructure"
        ShapeType.MEMBER, ShapeType.SERVICE, ShapeType.RESOURCE, ShapeType.OPERATION, null ->
            throw Exception("Unsupported member target type: ${type}")
    }
