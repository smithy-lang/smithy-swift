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
    val StructureSchema = runtimeSymbol("StructureSchema", SwiftDeclaration.STRUCT, listOf("SchemaBasedSerde"))
    val ListSchema = runtimeSymbol("ListSchema", SwiftDeclaration.STRUCT, listOf("SchemaBasedSerde"))
    val MapSchema = runtimeSymbol("MapSchema", SwiftDeclaration.STRUCT, listOf("SchemaBasedSerde"))
    val SimpleSchema = runtimeSymbol("SimpleSchema", SwiftDeclaration.STRUCT, listOf("SchemaBasedSerde"))
    val MemberSchema = runtimeSymbol("MemberSchema", SwiftDeclaration.STRUCT, listOf("SchemaBasedSerde"))
    val Member = runtimeSymbol("Member", SwiftDeclaration.STRUCT, listOf("SchemaBasedSerde"))
    val DeserializableShape = runtimeSymbol("DeserializableShape", SwiftDeclaration.PROTOCOL)
    val unitSchema = runtimeSymbol("unitSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val booleanSchema = runtimeSymbol("booleanSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val integerSchema = runtimeSymbol("integerSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val floatSchema = runtimeSymbol("floatSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val doubleSchema = runtimeSymbol("doubleSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val stringSchema = runtimeSymbol("stringSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
    val documentSchema = runtimeSymbol("documentSchema", SwiftDeclaration.LET, listOf("SchemaBasedSerde"))
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
