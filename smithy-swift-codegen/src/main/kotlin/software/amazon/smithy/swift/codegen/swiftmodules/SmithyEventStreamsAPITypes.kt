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
object SmithyEventStreamsAPITypes {
    val ExceptionParams = runtimeSymbol("MessageType.ExceptionParams")
    val Header = runtimeSymbol("Header")
    val Message = runtimeSymbol("Message")
    val MessageDecoder = runtimeSymbol("MessageDecoder")
    val UnmarshalClosure = runtimeSymbol("UnmarshalClosure")
    val MarshalClosure = runtimeSymbol("MarshalClosure")
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    SwiftDependency.SMITHY_EVENT_STREAMS_API,
)
