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
        val HttpClientEngine = runtimeSymbol("HttpClientEngine")
        val HttpClientConfiguration = runtimeSymbol("HttpClientConfiguration")
        val Headers = runtimeSymbol("Headers")
        val HttpStatusCode = runtimeSymbol("HttpStatusCode")
        val SdkHttpClient = runtimeSymbol("SdkHttpClient")
        val SdkHttpRequestBuilder = runtimeSymbol("SdkHttpRequestBuilder")
        val SdkHttpRequest = runtimeSymbol("SdkHttpRequest")
        val HttpResponse = runtimeSymbol("HttpResponse")
        val HttpResponseBinding = runtimeSymbol("HttpResponseBinding")
        val HttpResponseErrorBinding = runtimeSymbol("HttpResponseErrorBinding")
        val HttpError = runtimeSymbol("HTTPError")
        val UnknownHttpServiceError = runtimeSymbol("UnknownHttpServiceError")
        val HttpContextBuilder = runtimeSymbol("HttpContextBuilder")
    }

    object Serde {
        val RequestEncoder = runtimeSymbol("RequestEncoder")
        val ResponseDecoder = runtimeSymbol("ResponseDecoder")
        val Key = runtimeSymbol("Key")
        val DynamicNodeDecoding = runtimeSymbol("DynamicNodeDecoding")
        val NodeDecoding = runtimeSymbol("NodeDecoding")
        val MapEntry = runtimeSymbol("MapEntry")
        val CollectionMember = runtimeSymbol("CollectionMember")
        val MapKeyValue = runtimeSymbol("MapKeyValue")
        val FormURLEncoder = runtimeSymbol("FormURLEncoder")
        val JSONDecoder = runtimeSymbol("JSONDecoder")
        val JSONEncoder = runtimeSymbol("JSONEncoder")
        val JSONWriter = runtimeSymbol("JSONWriter")
        val FormURLWriter = runtimeSymbol("FormURLWriter")
        val XMLDecoder = runtimeSymbol("XMLDecoder")
        val MessageMarshallable = runtimeSymbol("MessageMarshallable")
        val MessageUnmarshallable = runtimeSymbol("MessageUnmarshallable")
        val JSONReadWrite = runtimeSymbol("JSONReadWrite")
        val FormURLReadWrite = runtimeSymbol("FormURLReadWrite")
    }

    object EventStream {
        val MessageDecoder = runtimeSymbol("MessageDecoder")
        val ExceptionParams = runtimeSymbol("EventStream.MessageType.ExceptionParams")
        val Header = runtimeSymbol("EventStream.Header")
        val Message = runtimeSymbol("EventStream.Message")
        val MessageEncoderStream = runtimeSymbol("EventStream.DefaultMessageEncoderStream")
        val MessageDecoderStream = runtimeSymbol("EventStream.DefaultMessageDecoderStream")
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
        val BodyMiddleware = runtimeSymbol("BodyMiddleware")
        val PayloadBodyMiddleware = runtimeSymbol("PayloadBodyMiddleware")
        val EventStreamBodyMiddleware = runtimeSymbol("EventStreamBodyMiddleware")
        val BlobStreamBodyMiddleware = runtimeSymbol("BlobStreamBodyMiddleware")
        val BlobBodyMiddleware = runtimeSymbol("BlobBodyMiddleware")
        val EnumBodyMiddleware = runtimeSymbol("EnumBodyMiddleware")
        val IntEnumBodyMiddleware = runtimeSymbol("IntEnumBodyMiddleware")
        val StringBodyMiddleware = runtimeSymbol("StringBodyMiddleware")

        object Providers {
            val URLPathProvider = runtimeSymbol("URLPathProvider")
            val QueryItemProvider = runtimeSymbol("QueryItemProvider")
            val HeaderProvider = runtimeSymbol("HeaderProvider")
        }
    }

    object Core {
        val AttributeKey = runtimeSymbol("AttributeKey")
        val Endpoint = runtimeSymbol("Endpoint")
        val ByteStream = runtimeSymbol("ByteStream")
        val Date = runtimeSymbol("Date")
        val Data = runtimeSymbol("Data")
        val Document = runtimeSymbol("Document")
        val SDKURLQueryItem = runtimeSymbol("SDKURLQueryItem")
        val URL = runtimeSymbol("URL")
        val ModeledError = runtimeSymbol("ModeledError")
        val UnknownClientError = runtimeSymbol("ClientError.unknownError")
        val ServiceError = runtimeSymbol("ServiceError")
        val Logger = runtimeSymbol("LogAgent")
        val SDKLogHandlerFactory = runtimeSymbol("SDKLogHandlerFactory")
        val SDKLogLevel = runtimeSymbol("SDKLogLevel")
        val ClientLogMode = runtimeSymbol("ClientLogMode")
        val IdempotencyTokenGenerator = runtimeSymbol("IdempotencyTokenGenerator")
        val DefaultRetryStrategy = runtimeSymbol("DefaultRetryStrategy")
        val RetryStrategyOptions = runtimeSymbol("RetryStrategyOptions")
        val DefaultRetryErrorInfoProvider = runtimeSymbol("DefaultRetryErrorInfoProvider")
        val DefaultSDKRuntimeConfiguration = runtimeSymbol("DefaultSDKRuntimeConfiguration")
        val DateFormatter = runtimeSymbol("DateFormatter")
        val PaginateToken = runtimeSymbol("PaginateToken")
        val PaginatorSequence = runtimeSymbol("PaginatorSequence")
    }
}

private fun runtimeSymbol(name: String): Symbol = buildSymbol {
    this.name = name
    this.namespace = SwiftDependency.CLIENT_RUNTIME.target
    dependency(SwiftDependency.CLIENT_RUNTIME)
}
