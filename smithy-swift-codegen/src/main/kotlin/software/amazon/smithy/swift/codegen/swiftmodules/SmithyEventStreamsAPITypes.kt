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
    val Header = runtimeSymbol("Header", SwiftDeclaration.STRUCT)
    val Message = runtimeSymbol("Message", SwiftDeclaration.STRUCT)
    val MessageType = runtimeSymbol("MessageType", SwiftDeclaration.ENUM)
    val MessageDecoder = runtimeSymbol("MessageDecoder", SwiftDeclaration.PROTOCOL)
    val UnmarshalClosure = runtimeSymbol("UnmarshalClosure", SwiftDeclaration.TYPEALIAS)
    val MarshalClosure = runtimeSymbol("MarshalClosure", SwiftDeclaration.TYPEALIAS)
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    SwiftDependency.SMITHY_EVENT_STREAMS_API,
    null,
)
