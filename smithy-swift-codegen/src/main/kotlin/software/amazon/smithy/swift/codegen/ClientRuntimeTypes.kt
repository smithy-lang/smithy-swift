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
    }

    object Serde {
        val RequestEncoder = runtimeSymbol("RequestEncoder")
        val ResponseDecoder = runtimeSymbol("ResponseDecoder")
    }

    object Middleware {
        val OperationOutput = runtimeSymbol("OperationOutput")
        val Middleware = runtimeSymbol("Middleware")
        val Context = runtimeSymbol("Context")
    }

    object Core {
        val URLQueryItem = runtimeSymbol("URLQueryItem", false)
        val ClientError = runtimeSymbol("ClientError", false)
        val SdkError = runtimeSymbol("SdkError")
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
    }
}

private fun runtimeSymbol(name: String, optional: Boolean = true): Symbol = buildSymbol {
    this.name = name
    this.nullable = optional
    this.namespace = SwiftDependency.CLIENT_RUNTIME.target
    dependency(SwiftDependency.CLIENT_RUNTIME)
}
