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
object ClientRuntimeTypes {
    object Http {
        val HttpClientConfiguration = runtimeSymbol("HttpClientConfiguration", SwiftDeclaration.CLASS)
        val HttpError = runtimeSymbol("HTTPError", SwiftDeclaration.PROTOCOL)
        val SdkHttpClient = runtimeSymbol("SdkHttpClient", SwiftDeclaration.CLASS)
        val UnknownHttpServiceError = runtimeSymbol("UnknownHTTPServiceError", SwiftDeclaration.STRUCT)
    }

    object Middleware {
        val OperationOutput = runtimeSymbol("OperationOutput", SwiftDeclaration.STRUCT)
        val Middleware = runtimeSymbol("Middleware", SwiftDeclaration.PROTOCOL)
        val LoggerMiddleware = runtimeSymbol("LoggerMiddleware", SwiftDeclaration.STRUCT)
        val ContentLengthMiddleware = runtimeSymbol("ContentLengthMiddleware", SwiftDeclaration.STRUCT)
        val ContentTypeMiddleware = runtimeSymbol("ContentTypeMiddleware", SwiftDeclaration.STRUCT)
        val ContentMD5Middleware = runtimeSymbol("ContentMD5Middleware", SwiftDeclaration.STRUCT)
        val DeserializeMiddleware = runtimeSymbol("DeserializeMiddleware", SwiftDeclaration.STRUCT)
        val MutateHeadersMiddleware = runtimeSymbol("MutateHeadersMiddleware", SwiftDeclaration.STRUCT)
        val OperationStack = runtimeSymbol("OperationStack", SwiftDeclaration.STRUCT)
        val URLHostMiddleware = runtimeSymbol("URLHostMiddleware", SwiftDeclaration.STRUCT)
        val URLPathMiddleware = runtimeSymbol("URLPathMiddleware", SwiftDeclaration.STRUCT)
        val QueryItemMiddleware = runtimeSymbol("QueryItemMiddleware", SwiftDeclaration.STRUCT)
        val HeaderMiddleware = runtimeSymbol("HeaderMiddleware", SwiftDeclaration.STRUCT)
        val RetryMiddleware = runtimeSymbol("RetryMiddleware", SwiftDeclaration.STRUCT)
        val IdempotencyTokenMiddleware =
            runtimeSymbol("IdempotencyTokenMiddleware", SwiftDeclaration.STRUCT)
        val NoopHandler = runtimeSymbol("NoopHandler", SwiftDeclaration.STRUCT)
        val SignerMiddleware = runtimeSymbol("SignerMiddleware", SwiftDeclaration.STRUCT)
        val AuthSchemeMiddleware = runtimeSymbol("AuthSchemeMiddleware", SwiftDeclaration.STRUCT)
        val BodyMiddleware = runtimeSymbol("BodyMiddleware", SwiftDeclaration.STRUCT)
        val PayloadBodyMiddleware = runtimeSymbol("PayloadBodyMiddleware", SwiftDeclaration.STRUCT)
        val EventStreamBodyMiddleware = runtimeSymbol("EventStreamBodyMiddleware", SwiftDeclaration.STRUCT)
        val BlobStreamBodyMiddleware = runtimeSymbol("BlobStreamBodyMiddleware", SwiftDeclaration.STRUCT)
        val BlobBodyMiddleware = runtimeSymbol("BlobBodyMiddleware", SwiftDeclaration.STRUCT)
        val EnumBodyMiddleware = runtimeSymbol("EnumBodyMiddleware", SwiftDeclaration.STRUCT)
        val IntEnumBodyMiddleware = runtimeSymbol("IntEnumBodyMiddleware", SwiftDeclaration.STRUCT)
        val StringBodyMiddleware = runtimeSymbol("StringBodyMiddleware", SwiftDeclaration.STRUCT)
        val HttpInterceptor = runtimeSymbol("HttpInterceptor", SwiftDeclaration.PROTOCOL)
        val MutableInput = runtimeSymbol("MutableInput", SwiftDeclaration.PROTOCOL)
        val Handler = runtimeSymbol("Handler", SwiftDeclaration.PROTOCOL)
        val OrchestratorBuilder = runtimeSymbol("OrchestratorBuilder", SwiftDeclaration.CLASS)
    }

    object Core {
        val Client = runtimeSymbol("Client", SwiftDeclaration.PROTOCOL)
        val ModeledError = runtimeSymbol("ModeledError", SwiftDeclaration.PROTOCOL)
        val ServiceError = runtimeSymbol("ServiceError", SwiftDeclaration.PROTOCOL)
        val ErrorFault = runtimeSymbol("ErrorFault", SwiftDeclaration.ENUM)
        val TelemetryProvider = runtimeSymbol("TelemetryProvider", SwiftDeclaration.PROTOCOL)
        val SDKLogHandlerFactory = runtimeSymbol("SDKLogHandlerFactory", SwiftDeclaration.PROTOCOL)
        val SDKLogLevel = runtimeSymbol("SDKLogLevel", SwiftDeclaration.ENUM)
        val ClientLogMode = runtimeSymbol("ClientLogMode", SwiftDeclaration.ENUM)
        val IdempotencyTokenGenerator = runtimeSymbol("IdempotencyTokenGenerator", SwiftDeclaration.PROTOCOL)
        val DefaultRetryErrorInfoProvider = runtimeSymbol("DefaultRetryErrorInfoProvider", SwiftDeclaration.ENUM)
        val PaginateToken = runtimeSymbol("PaginateToken", SwiftDeclaration.PROTOCOL)
        val PaginatorSequence = runtimeSymbol("PaginatorSequence", SwiftDeclaration.STRUCT)
        val EndpointsRuleEngine = runtimeSymbol("EndpointsRuleEngine", SwiftDeclaration.CLASS)
        val EndpointsRequestContext = runtimeSymbol("EndpointsRequestContext", SwiftDeclaration.CLASS)
        val EndpointsRequestContextProviding = runtimeSymbol("EndpointsRequestContextProviding", SwiftDeclaration.PROTOCOL)
        val EndpointError = runtimeSymbol("EndpointError", SwiftDeclaration.ENUM)
        val PartitionDefinition = runtimeSymbol("partitionJSON", SwiftDeclaration.LET)
        val EndpointsAuthSchemeResolver = runtimeSymbol("EndpointsAuthSchemeResolver", SwiftDeclaration.PROTOCOL)
        val DefaultEndpointsAuthSchemeResolver = runtimeSymbol("DefaultEndpointsAuthSchemeResolver", SwiftDeclaration.STRUCT)
        val EndpointsAuthScheme = runtimeSymbol("EndpointsAuthScheme", SwiftDeclaration.ENUM)
        val DefaultEndpointResolver = runtimeSymbol("DefaultEndpointResolver", SwiftDeclaration.STRUCT)
        val EndpointResolverMiddleware = runtimeSymbol("EndpointResolverMiddleware", SwiftDeclaration.STRUCT)
        val Plugin = runtimeSymbol("Plugin", SwiftDeclaration.PROTOCOL)
        val ClientConfiguration = runtimeSymbol("ClientConfiguration", SwiftDeclaration.PROTOCOL)
        val DefaultClientConfiguration = runtimeSymbol("DefaultClientConfiguration", SwiftDeclaration.PROTOCOL)
        val DefaultHttpClientConfiguration = runtimeSymbol("DefaultHttpClientConfiguration", SwiftDeclaration.PROTOCOL)
        val ClientConfigurationDefaults = runtimeSymbol("ClientConfigurationDefaults", SwiftDeclaration.TYPEALIAS)
        val ClientBuilder = runtimeSymbol("ClientBuilder", SwiftDeclaration.CLASS)
        val Indirect = runtimeSymbol("Indirect", SwiftDeclaration.CLASS)
        val HeaderDeserializationError = runtimeSymbol("HeaderDeserializationError", SwiftDeclaration.ENUM)
        val quoteHeaderValue = runtimeSymbol("quoteHeaderValue", SwiftDeclaration.FUNC)
        val DefaultClientPlugin = runtimeSymbol("DefaultClientPlugin", SwiftDeclaration.CLASS)
        val DefaultTelemetry = runtimeSymbol("DefaultTelemetry", SwiftDeclaration.ENUM)
        val splitHeaderListValues = runtimeSymbol("splitHeaderListValues", SwiftDeclaration.FUNC)
        val splitHttpDateHeaderListValues = runtimeSymbol("splitHttpDateHeaderListValues", SwiftDeclaration.FUNC)
        val OrchestratorBuilder = runtimeSymbol("OrchestratorBuilder", SwiftDeclaration.CLASS)
        val InterceptorProviders = runtimeSymbolWithoutNamespace("[ClientRuntime.InterceptorProvider]")
        val InterceptorProvider = runtimeSymbol("InterceptorProvider", SwiftDeclaration.PROTOCOL)
        val HttpInterceptorProviders = runtimeSymbolWithoutNamespace("[ClientRuntime.HttpInterceptorProvider]")
        val HttpInterceptorProvider = runtimeSymbol("HttpInterceptorProvider", SwiftDeclaration.PROTOCOL)
        val HttpInterceptor = runtimeSymbol("HttpInterceptor", SwiftDeclaration.PROTOCOL)
    }
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    SwiftDependency.CLIENT_RUNTIME,
    null,
)

private fun runtimeSymbolWithoutNamespace(name: String, declaration: SwiftDeclaration? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    null,
    null,
)
