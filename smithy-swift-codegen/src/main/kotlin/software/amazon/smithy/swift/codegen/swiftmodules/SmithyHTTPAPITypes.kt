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
object SmithyHTTPAPITypes {
    val Endpoint = runtimeSymbol("Endpoint", SwiftDeclaration.STRUCT)
    val HttpClient = runtimeSymbol("HTTPClient", SwiftDeclaration.PROTOCOL)
    val Headers = runtimeSymbol("Headers", SwiftDeclaration.STRUCT)
    val SdkHttpRequestBuilder = runtimeSymbol("SdkHttpRequestBuilder", SwiftDeclaration.CLASS)
    val SdkHttpRequest = runtimeSymbol("SdkHttpRequest", SwiftDeclaration.CLASS)
    val HttpResponse = runtimeSymbol("HttpResponse", SwiftDeclaration.CLASS)
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    SwiftDependency.SMITHY_HTTP_API,
)
