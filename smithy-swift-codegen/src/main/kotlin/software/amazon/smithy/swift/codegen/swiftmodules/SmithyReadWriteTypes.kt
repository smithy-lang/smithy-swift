package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.SwiftDependency

/**
 * Commonly used runtime types. Provides a single definition of a runtime symbol such that codegen isn't littered
 * with inline symbol creation which makes refactoring of the runtime more difficult and error prone.
 *
 * NOTE: Not all symbols need be added here but it doesn't hurt to define runtime symbols once.
 */
object SmithyReadWriteTypes {
    val SmithyReader = runtimeSymbol("SmithyReader", SwiftDeclaration.PROTOCOL)
    val SmithyWriter = runtimeSymbol("SmithyWriter", SwiftDeclaration.PROTOCOL)
    val ReaderError = runtimeSymbol("ReaderError", SwiftDeclaration.ENUM, emptyList())
    val mapWritingClosure = runtimeSymbol("mapWritingClosure", SwiftDeclaration.FUNC)
    val listWritingClosure = runtimeSymbol("listWritingClosure", SwiftDeclaration.FUNC)
    val timestampWritingClosure = runtimeSymbol("timestampWritingClosure", SwiftDeclaration.FUNC)
    val mapReadingClosure = runtimeSymbol("mapReadingClosure", SwiftDeclaration.FUNC)
    val listReadingClosure = runtimeSymbol("listReadingClosure", SwiftDeclaration.FUNC)
    val timestampReadingClosure = runtimeSymbol("timestampReadingClosure", SwiftDeclaration.FUNC)
    val sparseFormOf = runtimeSymbol("sparseFormOf", SwiftDeclaration.FUNC)
    val optionalFormOf = runtimeSymbol("optionalFormOf", SwiftDeclaration.FUNC)
    val ReadingClosures = runtimeSymbol("ReadingClosures", SwiftDeclaration.ENUM)
    val WritingClosures = runtimeSymbol("WritingClosures", SwiftDeclaration.ENUM)
    val ReadingClosureBox = runtimeSymbol("ReadingClosureBox", SwiftDeclaration.STRUCT)
    val WritingClosureBox = runtimeSymbol("WritingClosureBox", SwiftDeclaration.STRUCT)
    val StructureSchema = runtimeSymbol("StructureSchema", SwiftDeclaration.CLASS, listOf("SchemaBasedSerde"))
    val ListSchema = runtimeSymbol("ListSchema", SwiftDeclaration.CLASS, listOf("SchemaBasedSerde"))
    val MapSchema = runtimeSymbol("MapSchema", SwiftDeclaration.CLASS, listOf("SchemaBasedSerde"))
    val SimpleSchema = runtimeSymbol("SimpleSchema", SwiftDeclaration.CLASS, listOf("SchemaBasedSerde"))
    val MemberSchema = runtimeSymbol("MemberSchema", SwiftDeclaration.CLASS, listOf("SchemaBasedSerde"))
    val DeserializableShape = runtimeSymbol("DeserializableShape", SwiftDeclaration.PROTOCOL)
    val ShapeDeserializer = runtimeSymbol("ShapeDeserializer", SwiftDeclaration.PROTOCOL, listOf("SchemaBasedSerde"))
    val unitSchema = runtimeSymbol("unitSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val booleanSchema = runtimeSymbol("booleanSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val byteSchema = runtimeSymbol("byteSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val shortSchema = runtimeSymbol("shortSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val integerSchema = runtimeSymbol("integerSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val longSchema = runtimeSymbol("longSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val floatSchema = runtimeSymbol("floatSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val doubleSchema = runtimeSymbol("doubleSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val stringSchema = runtimeSymbol("stringSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val documentSchema = runtimeSymbol("documentSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val blobSchema = runtimeSymbol("blobSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val timestampSchema = runtimeSymbol("timestampSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
}

private fun runtimeSymbol(
    name: String,
    declaration: SwiftDeclaration,
    spiName: List<String> = listOf("SmithyReadWrite")
): Symbol = SwiftSymbol.make(
    name,
    declaration,
    SwiftDependency.SMITHY_READ_WRITE,
    emptyList(),
    spiName,
)
