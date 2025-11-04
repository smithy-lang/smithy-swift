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
object SmithyTypes {
    val ByteStream = runtimeSymbol("ByteStream", SwiftDeclaration.ENUM)
    val Attributes = runtimeSymbol("Attributes", SwiftDeclaration.STRUCT)
    val AttributeKey = runtimeSymbol("AttributeKey", SwiftDeclaration.STRUCT)
    val ClientError = runtimeSymbol("ClientError", SwiftDeclaration.ENUM)
    val Context = runtimeSymbol("Context", SwiftDeclaration.CLASS)
    val ContextBuilder = runtimeSymbol("ContextBuilder", SwiftDeclaration.CLASS)
    val Document = runtimeSymbol("Document", SwiftDeclaration.STRUCT)
    val LogAgent = runtimeSymbol("LogAgent", SwiftDeclaration.PROTOCOL)
    val RequestMessageSerializer = runtimeSymbol("RequestMessageSerializer", SwiftDeclaration.PROTOCOL)
    val URIQueryItem = runtimeSymbol("URIQueryItem", SwiftDeclaration.STRUCT)
    val Schema = runtimeSymbol("Schema", SwiftDeclaration.CLASS)
    val unitSchema = runtimeSymbol("unitSchema", SwiftDeclaration.VAR)
    val stringSchema = runtimeSymbol("stringSchema", SwiftDeclaration.VAR)
    val blobSchema = runtimeSymbol("blobSchema", SwiftDeclaration.VAR)
    val integerSchema = runtimeSymbol("integerSchema", SwiftDeclaration.VAR)
    val timestampSchema = runtimeSymbol("timestampSchema", SwiftDeclaration.VAR)
    val booleanSchema = runtimeSymbol("booleanSchema", SwiftDeclaration.VAR)
    val floatSchema = runtimeSymbol("floatSchema", SwiftDeclaration.VAR)
    val doubleSchema = runtimeSymbol("doubleSchema", SwiftDeclaration.VAR)
    val longSchema = runtimeSymbol("longSchema", SwiftDeclaration.VAR)
    val shortSchema = runtimeSymbol("shortSchema", SwiftDeclaration.VAR)
    val byteSchema = runtimeSymbol("byteSchema", SwiftDeclaration.VAR)
    val primitiveBooleanSchema = runtimeSymbol("primitiveBooleanSchema", SwiftDeclaration.VAR)
    val primitiveFloatSchema = runtimeSymbol("primitiveFloatSchema", SwiftDeclaration.VAR)
    val primitiveDoubleSchema = runtimeSymbol("primitiveDoubleSchema", SwiftDeclaration.VAR)
    val primitiveLongSchema = runtimeSymbol("primitiveLongSchema", SwiftDeclaration.VAR)
    val primitiveIntegerSchema = runtimeSymbol("primitiveIntegerSchema", SwiftDeclaration.VAR)
    val primitiveShortSchema = runtimeSymbol("primitiveShortSchema", SwiftDeclaration.VAR)
    val primitiveByteSchema = runtimeSymbol("primitiveByteSchema", SwiftDeclaration.VAR)
    val documentSchema = runtimeSymbol("documentSchema", SwiftDeclaration.VAR)
}

private fun runtimeSymbol(
    name: String,
    declaration: SwiftDeclaration?,
    additionalImports: List<Symbol> = emptyList(),
    spiName: List<String> = emptyList(),
): Symbol =
    SwiftSymbol.make(
        name,
        declaration,
        SwiftDependency.SMITHY.takeIf { additionalImports.isEmpty() },
        additionalImports,
        spiName,
    )
