package software.amazon.smithy.swift.codegen.integration.serde.schema

import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.swift.codegen.customtraits.NestedTrait
import software.amazon.smithy.swift.codegen.model.hasTrait
import kotlin.jvm.optionals.getOrNull

val Shape.schemaVar: String
    get() = if (this.id.toString() == "smithy.api#Unit" && !this.hasTrait<NestedTrait>()) {
        ShapeId.from("smithy.api#EnumUnit").schemaVarName()
    } else {
        this.id.schemaVarName()
    }

private fun ShapeId.schemaVarName(): String {
    val namespacePortion = this.namespace.replace(".", "_")
    val memberPortion = this.member.getOrNull()?.let { "_member_$it" } ?: ""
    return "${namespacePortion}__${this.name}_schema${memberPortion}"
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
