package software.amazon.smithy.swift.codegen.integration.serde.schema

import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTypes
import kotlin.jvm.optionals.getOrNull

fun Shape.schemaVar(writer: SwiftWriter): String =
    if (this.id.namespace == "smithy.api") {
        this.id.preludeSchemaVarName(writer)
    } else {
        this.id.schemaVarName()
    }

private fun ShapeId.preludeSchemaVarName(writer: SwiftWriter): String =
    when (this.name) {
        "Unit" -> writer.format("\$N", SmithyTypes.unitSchema)
        "String" -> writer.format("\$N", SmithyTypes.stringSchema)
        "Blob" -> writer.format("\$N", SmithyTypes.blobSchema)
        "Integer" -> writer.format("\$N", SmithyTypes.integerSchema)
        "Timestamp" -> writer.format("\$N", SmithyTypes.timestampSchema)
        "Boolean" -> writer.format("\$N", SmithyTypes.booleanSchema)
        "Float" -> writer.format("\$N", SmithyTypes.floatSchema)
        "Double" -> writer.format("\$N", SmithyTypes.doubleSchema)
        "Long" -> writer.format("\$N", SmithyTypes.longSchema)
        "Short" -> writer.format("\$N", SmithyTypes.shortSchema)
        "Byte" -> writer.format("\$N", SmithyTypes.byteSchema)
        "PrimitiveInteger" -> writer.format("\$N", SmithyTypes.primitiveIntegerSchema)
        "PrimitiveBoolean" -> writer.format("\$N", SmithyTypes.primitiveBooleanSchema)
        "PrimitiveFloat" -> writer.format("\$N", SmithyTypes.primitiveFloatSchema)
        "PrimitiveDouble" -> writer.format("\$N", SmithyTypes.primitiveDoubleSchema)
        "PrimitiveLong" -> writer.format("\$N", SmithyTypes.primitiveLongSchema)
        "PrimitiveShort" -> writer.format("\$N", SmithyTypes.primitiveShortSchema)
        "PrimitiveByte" -> writer.format("\$N", SmithyTypes.primitiveByteSchema)
        "Document" -> writer.format("\$N", SmithyTypes.documentSchema)
        else -> throw Exception("Unhandled prelude type converted to schemaVar: ${this.name}")
    }

private fun ShapeId.schemaVarName(): String {
    assert(this.member.getOrNull() == null)
    val namespacePortion = this.namespace.replace(".", "_")
    val namePortion = this.name
    return "schema__${namespacePortion}__${namePortion}"
}

val Shape.readMethodName: String
    get() =
        when (type) {
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
                throw Exception("Unsupported member target type: $type")
        }
