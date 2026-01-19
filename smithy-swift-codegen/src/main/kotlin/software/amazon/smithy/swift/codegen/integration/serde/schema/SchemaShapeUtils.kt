package software.amazon.smithy.swift.codegen.integration.serde.schema

import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTypes
import kotlin.jvm.optionals.getOrNull

fun Shape.schemaVar(writer: SwiftWriter): String =
    if (this.id.namespace == "smithy.api") {
        this.id.preludeSchemaVarName(writer)
    } else {
        this.id.schemaVarName()
    }

private fun ShapeId.preludeSchemaVarName(writer: SwiftWriter): String {
    val propertyName =
        when (this.name) {
            "Unit" -> "unitSchema"
            "String" -> "stringSchema"
            "Blob" -> "blobSchema"
            "Integer" -> "integerSchema"
            "Timestamp" -> "timestampSchema"
            "Boolean" -> "booleanSchema"
            "Float" -> "floatSchema"
            "Double" -> "doubleSchema"
            "Long" -> "longSchema"
            "Short" -> "shortSchema"
            "Byte" -> "byteSchema"
            "PrimitiveInteger" -> "primitiveIntegerSchema"
            "PrimitiveBoolean" -> "primitiveBooleanSchema"
            "PrimitiveFloat" -> "primitiveFloatSchema"
            "PrimitiveDouble" -> "primitiveDoubleSchema"
            "PrimitiveLong" -> "primitiveLongSchema"
            "PrimitiveShort" -> "primitiveShortSchema"
            "PrimitiveByte" -> "primitiveByteSchema"
            "Document" -> "documentSchema"
            else -> throw Exception("Unhandled prelude type converted to schemaVar: ${this.name}")
        }
    return writer.format("\$N.\$L", SmithyTypes.Prelude, propertyName)
}

private fun ShapeId.schemaVarName(): String {
    assert(this.member.getOrNull() == null)
    val namespacePortion = this.namespace.replace(".", "_")
    val namePortion = this.name
    return "schema__${namespacePortion}__$namePortion"
}
