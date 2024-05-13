package software.amazon.smithy.swift.codegen.endpoints

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.model.buildSymbol

object EndpointTypes {
    val EndpointResolver = symbol("EndpointResolver")
    val EndpointParams = symbol("EndpointParams")
    val EndpointResolverMiddleware = symbol("EndpointResolverMiddleware")
    val DefaultEndpointResolver = symbol("DefaultEndpointResolver")

    private fun symbol(name: String): Symbol = buildSymbol {
        this.name = name
    }
}
