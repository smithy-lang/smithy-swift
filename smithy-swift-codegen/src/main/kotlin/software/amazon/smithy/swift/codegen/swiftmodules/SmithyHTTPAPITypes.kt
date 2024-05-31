package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.model.buildSymbol

/**
 * Commonly used runtime types. Provides a single definition of a runtime symbol such that codegen isn't littered
 * with inline symbol creation which makes refactoring of the runtime more difficult and error prone.
 *
 * NOTE: Not all symbols need be added here but it doesn't hurt to define runtime symbols once.
 */
object SmithyHTTPAPITypes {
    val Endpoint = runtimeSymbol("Endpoint")
    val HttpClient = runtimeSymbol("HTTPClient")
    val Headers = runtimeSymbol("Headers")
    val SdkHttpRequestBuilder = runtimeSymbol("SdkHttpRequestBuilder")
    val SdkHttpRequest = runtimeSymbol("SdkHttpRequest")
    val HttpResponse = runtimeSymbol("HttpResponse")
    val HttpResponseBinding = runtimeSymbol("HttpResponseBinding")
}

private fun runtimeSymbol(name: String): Symbol = buildSymbol {
    this.name = name
    this.namespace = SwiftDependency.SMITHY_HTTP_API.target
    this.dependency(SwiftDependency.SMITHY_HTTP_API)
}
