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
        val HttpClientConfiguration = runtimeSymbol("HttpClientConfiguration")
        val HttpError = runtimeSymbol("HTTPError")
        val SdkHttpClient = runtimeSymbol("SdkHttpClient")
        val UnknownHttpServiceError = runtimeSymbol("UnknownHTTPServiceError")
    }

    object Middleware {
        val OperationOutput = runtimeSymbol("OperationOutput")
        val Middleware = runtimeSymbol("Middleware")
        val LoggerMiddleware = runtimeSymbol("LoggerMiddleware")
        val ContentLengthMiddleware = runtimeSymbol("ContentLengthMiddleware")
        val ContentMD5Middleware = runtimeSymbol("ContentMD5Middleware")
        val FlexibleChecksumsRequestMiddleware =
            runtimeSymbol("FlexibleChecksumsRequestMiddleware")
        val FlexibleChecksumsResponseMiddleware =
            runtimeSymbol("FlexibleChecksumsResponseMiddleware")
        val DeserializeMiddleware = runtimeSymbol("DeserializeMiddleware")
        val MutateHeadersMiddleware = runtimeSymbol("MutateHeadersMiddleware")
        val OperationStack = runtimeSymbol("OperationStack")
        val URLHostMiddleware = runtimeSymbol("URLHostMiddleware")
        val URLPathMiddleware = runtimeSymbol("URLPathMiddleware")
        val QueryItemMiddleware = runtimeSymbol("QueryItemMiddleware")
        val HeaderMiddleware = runtimeSymbol("HeaderMiddleware")
        val RetryMiddleware = runtimeSymbol("RetryMiddleware")
        val IdempotencyTokenMiddleware =
            runtimeSymbol("IdempotencyTokenMiddleware")
        val NoopHandler = runtimeSymbol("NoopHandler")
        val SignerMiddleware = runtimeSymbol("SignerMiddleware")
        val AuthSchemeMiddleware = runtimeSymbol("AuthSchemeMiddleware")
        val BodyMiddleware = runtimeSymbol("BodyMiddleware")
        val PayloadBodyMiddleware = runtimeSymbol("PayloadBodyMiddleware")
        val EventStreamBodyMiddleware = runtimeSymbol("EventStreamBodyMiddleware")
        val BlobStreamBodyMiddleware = runtimeSymbol("BlobStreamBodyMiddleware")
        val BlobBodyMiddleware = runtimeSymbol("BlobBodyMiddleware")
        val EnumBodyMiddleware = runtimeSymbol("EnumBodyMiddleware")
        val IntEnumBodyMiddleware = runtimeSymbol("IntEnumBodyMiddleware")
        val StringBodyMiddleware = runtimeSymbol("StringBodyMiddleware")
    }

    object Core {
        val ModeledError = runtimeSymbol("ModeledError", SwiftDeclaration.PROTOCOL)
        val ServiceError = runtimeSymbol("ServiceError", SwiftDeclaration.PROTOCOL)
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
        val PartitionDefinition = runtimeSymbol("partitionJSON", SwiftDeclaration.LET)
        val EndpointsAuthSchemeResolver = runtimeSymbol("EndpointsAuthSchemeResolver", SwiftDeclaration.PROTOCOL)
        val DefaultEndpointsAuthSchemeResolver = runtimeSymbol("DefaultEndpointsAuthSchemeResolver", SwiftDeclaration.STRUCT)
        val EndpointsAuthScheme = runtimeSymbol("EndpointsAuthScheme", SwiftDeclaration.ENUM)
        val DefaultEndpointResolver = runtimeSymbol("DefaultEndpointResolver", SwiftDeclaration.STRUCT)
        val EndpointResolverMiddleware = runtimeSymbol("EndpointResolverMiddleware", SwiftDeclaration.STRUCT)
    }
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    SwiftDependency.CLIENT_RUNTIME,
)
