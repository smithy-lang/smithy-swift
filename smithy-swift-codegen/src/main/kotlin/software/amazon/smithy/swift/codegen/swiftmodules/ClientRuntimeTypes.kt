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
        val ModeledError = runtimeSymbol("ModeledError")
        val ServiceError = runtimeSymbol("ServiceError")
        val TelemetryProvider = runtimeSymbol("TelemetryProvider")
        val SDKLogHandlerFactory = runtimeSymbol("SDKLogHandlerFactory")
        val SDKLogLevel = runtimeSymbol("SDKLogLevel")
        val ClientLogMode = runtimeSymbol("ClientLogMode")
        val IdempotencyTokenGenerator = runtimeSymbol("IdempotencyTokenGenerator")
        val DefaultRetryErrorInfoProvider =
            runtimeSymbol("DefaultRetryErrorInfoProvider")
        val PaginateToken = runtimeSymbol("PaginateToken")
        val PaginatorSequence = runtimeSymbol("PaginatorSequence")
        val EndpointsRuleEngine = runtimeSymbol("EndpointsRuleEngine")
        val EndpointsRequestContext = runtimeSymbol("EndpointsRequestContext")
        val PartitionDefinition = runtimeSymbol("partitionJSON")
        val EndpointsAuthSchemeResolver =
            runtimeSymbol("EndpointsAuthSchemeResolver")
        val DefaultEndpointsAuthSchemeResolver =
            runtimeSymbol("DefaultEndpointsAuthSchemeResolver")
        val EndpointsAuthScheme = runtimeSymbol("EndpointsAuthScheme")
    }
}

private fun runtimeSymbol(name: String): Symbol = buildSymbol {
    this.name = name
    this.namespace = SwiftDependency.CLIENT_RUNTIME.target
    dependency(SwiftDependency.CLIENT_RUNTIME)
}
