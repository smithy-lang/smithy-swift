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
    val Document = runtimeSymbol("Document", SwiftDeclaration.ENUM, emptyList())
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
