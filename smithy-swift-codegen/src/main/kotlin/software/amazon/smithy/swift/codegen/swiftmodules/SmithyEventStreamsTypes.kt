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
object SmithyEventStreamsTypes {
    val DefaultMessageEncoder = runtimeSymbol("DefaultMessageEncoder", SwiftDeclaration.CLASS)
    val DefaultMessageDecoder = runtimeSymbol("DefaultMessageDecoder", SwiftDeclaration.CLASS)
    val DefaultMessageEncoderStream = runtimeSymbol("DefaultMessageEncoderStream", SwiftDeclaration.CLASS)
    val DefaultMessageDecoderStream = runtimeSymbol("DefaultMessageDecoderStream", SwiftDeclaration.STRUCT)
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    SwiftDependency.SMITHY_EVENT_STREAMS,
    null,
)
