/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.model.buildSymbol

/**
 * Commonly used runtime types. Provides a single definition of a runtime symbol such that codegen isn't littered
 * with inline symbol creation which makes refactoring of the runtime more difficult and error prone.
 *
 * NOTE: Not all symbols need be added here but it doesn't hurt to define runtime symbols once.
 */
object ClientRuntimeTypes {
    object Http {
        val HttpClient = runtimeSymbol("HTTPClient")
        val HttpClientConfiguration = runtimeSymbol("HttpClientConfiguration")
        val Headers = runtimeSymbol("Headers")
        val SdkHttpClient = runtimeSymbol("SdkHttpClient")
        val SdkHttpRequestBuilder = runtimeSymbol("SdkHttpRequestBuilder")
        val SdkHttpRequest = runtimeSymbol("SdkHttpRequest")
        val HttpResponse = runtimeSymbol("HttpResponse")
        val HttpResponseBinding = runtimeSymbol("HttpResponseBinding")
        val HttpError = runtimeSymbol("HTTPError")
        val UnknownHttpServiceError = runtimeSymbol("UnknownHTTPServiceError")
        val HttpContext = runtimeSymbol("HttpContext")
        val HttpContextBuilder = runtimeSymbol("HttpContextBuilder")
    }

    object EventStream {
        val MessageDecoder = runtimeSymbol("MessageDecoder")
        val ExceptionParams = runtimeSymbol("EventStream.MessageType.ExceptionParams")
        val Header = runtimeSymbol("EventStream.Header")
        val Message = runtimeSymbol("EventStream.Message")
        val MessageEncoderStream = runtimeSymbol("EventStream.DefaultMessageEncoderStream")
        val MessageDecoderStream = runtimeSymbol("EventStream.DefaultMessageDecoderStream")
        val UnmarshalClosure = runtimeSymbol("UnmarshalClosure")
        val MarshalClosure = runtimeSymbol("MarshalClosure")
    }

    object Middleware {
        val OperationOutput = runtimeSymbol("OperationOutput")
        val Middleware = runtimeSymbol("Middleware")
        val LoggerMiddleware = runtimeSymbol("LoggerMiddleware")
        val ContentLengthMiddleware = runtimeSymbol("ContentLengthMiddleware")
        val ContentMD5Middleware = runtimeSymbol("ContentMD5Middleware")
        val FlexibleChecksumsRequestMiddleware = runtimeSymbol("FlexibleChecksumsRequestMiddleware")
        val FlexibleChecksumsResponseMiddleware = runtimeSymbol("FlexibleChecksumsResponseMiddleware")
        val DeserializeMiddleware = runtimeSymbol("DeserializeMiddleware")
        val MutateHeadersMiddleware = runtimeSymbol("MutateHeadersMiddleware")
        val OperationStack = runtimeSymbol("OperationStack")
        val URLHostMiddleware = runtimeSymbol("URLHostMiddleware")
        val URLPathMiddleware = runtimeSymbol("URLPathMiddleware")
        val QueryItemMiddleware = runtimeSymbol("QueryItemMiddleware")
        val HeaderMiddleware = runtimeSymbol("HeaderMiddleware")
        val RetryMiddleware = runtimeSymbol("RetryMiddleware")
        val IdempotencyTokenMiddleware = runtimeSymbol("IdempotencyTokenMiddleware")
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

    object Auth {
        val AuthSchemes = runtimeSymbolWithoutNamespace("[ClientRuntime.AuthScheme]")
        val AuthSchemeResolver = runtimeSymbol("AuthSchemeResolver")
        val AuthSchemeResolverParams = runtimeSymbol("AuthSchemeResolverParameters")
    }

    object Core {
        val Endpoint = runtimeSymbol("Endpoint", SwiftDeclaration.STRUCT)
        val Date = runtimeSymbol("Date", SwiftDeclaration.STRUCT)
        val Data = runtimeSymbol("Data", SwiftDeclaration.STRUCT)
        val SDKURLQueryItem = runtimeSymbol("SDKURLQueryItem", SwiftDeclaration.STRUCT)
        val URL = runtimeSymbol("URL", SwiftDeclaration.STRUCT)
        val ModeledError = runtimeSymbol("ModeledError", SwiftDeclaration.PROTOCOL)
        val UnknownClientError = runtimeSymbol("ClientError.unknownError")
        val ServiceError = runtimeSymbol("ServiceError", SwiftDeclaration.PROTOCOL)
        val Logger = runtimeSymbol("LogAgent", SwiftDeclaration.PROTOCOL)
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
        val PartitionDefinition = runtimeSymbol("partitionJSON", SwiftDeclaration.LET)
        val EndpointsAuthSchemeResolver = runtimeSymbol("EndpointsAuthSchemeResolver", SwiftDeclaration.PROTOCOL)
        val DefaultEndpointsAuthSchemeResolver = runtimeSymbol("DefaultEndpointsAuthSchemeResolver", SwiftDeclaration.STRUCT)
        val EndpointsAuthScheme = runtimeSymbol("EndpointsAuthScheme", SwiftDeclaration.ENUM)
    }
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null): Symbol = buildSymbol {
    this.name = name
    this.namespace = SwiftDependency.CLIENT_RUNTIME.target
    declaration?.let { this.setProperty("decl", it.keyword) }
    dependency(SwiftDependency.CLIENT_RUNTIME)
}

private fun runtimeSymbolWithoutNamespace(name: String): Symbol = buildSymbol {
    this.name = name
    dependency(SwiftDependency.CLIENT_RUNTIME)
}
