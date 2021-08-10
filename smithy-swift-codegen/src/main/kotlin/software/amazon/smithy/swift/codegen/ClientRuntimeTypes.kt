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
        val SdkHttpRequestBuilder = runtimeSymbol("SdkHttpRequestBuilder", false)
        val SdkHttpRequest = runtimeSymbol("SdkHttpRequest", false)
        val HttpBody = runtimeSymbol("HttpBody", false)
        val HttpResponse = runtimeSymbol("HttpResponse", false)
        val HttpResponseBinding = runtimeSymbol("HttpResponseBinding", false)
        val HttpServiceError = runtimeSymbol("HttpServiceError", false)
        val UnknownHttpServiceError = runtimeSymbol("UnknownHttpServiceError", false)
        val HttpContextBuilder = runtimeSymbol("HttpContextBuilder", false)
    }

    object Serde {
        val RequestEncoder = runtimeSymbol("RequestEncoder")
        val ResponseDecoder = runtimeSymbol("ResponseDecoder")
        val Key = runtimeSymbol("Key", false)
        val TimestampWrapper = runtimeSymbol("TimestampWrapper")
        val DynamicNodeDecoding = runtimeSymbol("DynamicNodeDecoding")
        val DynamicNodeEncoding = runtimeSymbol("DynamicNodeEncoding")
        val NodeDecoding = runtimeSymbol("NodeDecoding")
        val NodeEncoding = runtimeSymbol("NodeEncoding")
        val TimestampWrapperDecoder = runtimeSymbol("TimestampWrapperDecoder")
        val MapEntry = runtimeSymbol("MapEntry")
        val CollectionMember = runtimeSymbol("CollectionMember")
        val MapKeyValue = runtimeSymbol("MapKeyValue")
        val FormURLEncoder = runtimeSymbol("FormURLEncoder")
        val JSONDecoder = runtimeSymbol("JSONDecoder")
        val JSONEncoder = runtimeSymbol("JSONEncoder")
        val XMLEncoder = runtimeSymbol("XMLEncoder")
        val XMLDecoder = runtimeSymbol("XMLDecoder")
    }

    object Middleware {
        val OperationOutput = runtimeSymbol("OperationOutput")
        val Middleware = runtimeSymbol("Middleware")
    }

    object Core {
        val ByteStream = runtimeSymbol("ByteStream")
        val Date = runtimeSymbol("Date", false)
        val Data = runtimeSymbol("Data")
        val Document = runtimeSymbol("Document")
        val URLQueryItem = runtimeSymbol("URLQueryItem", false)
        val ClientError = runtimeSymbol("ClientError", false)
        val SdkError = runtimeSymbol("SdkError")
        val ServiceError = runtimeSymbol("ServiceError", false)
        val SdkResult = runtimeSymbol("SdkResult")
        val Logger = runtimeSymbol("LogAgent")
        val SDKLogHandlerFactory = runtimeSymbol("SDKLogHandlerFactory", false)
        val SDKLogLevel = runtimeSymbol("SDKLogLevel", false)
        val ClientLogMode = runtimeSymbol("ClientLogMode")
        val IdempotencyTokenGenerator = runtimeSymbol("IdempotencyTokenGenerator")
        val Retrier = runtimeSymbol("Retrier")
        val ErrorType = runtimeSymbol("ErrorType", false)
        val SDKRuntimeConfiguration = runtimeSymbol("SDKRuntimeConfiguration", false)
        val DefaultSDKRuntimeConfiguration = runtimeSymbol("DefaultSDKRuntimeConfiguration", false)
        val DateFormatter = runtimeSymbol("DateFormatter")
        val Reflection: Symbol = runtimeSymbol("Reflection")
    }
}

private fun runtimeSymbol(name: String, optional: Boolean = true): Symbol = buildSymbol {
    this.name = name
    this.nullable = optional
    this.namespace = SwiftDependency.CLIENT_RUNTIME.target
    dependency(SwiftDependency.CLIENT_RUNTIME)
}
