//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyHTTPAPI.HTTPClient
import SmithyIdentity
import SmithyIdentityAPI
import struct SmithyRetries.DefaultRetryStrategy
import struct SmithyRetries.ExponentialBackoffStrategy
import struct SmithyRetriesAPI.RetryStrategyOptions

public typealias RuntimeConfigType
    = DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>

open class ClientConfigDefaultsProvider {
    /// Returns a default `HTTPClient` engine.
    open class func httpClientEngine(
        _ config: HttpClientConfiguration? = nil
    ) -> HTTPClient {
        return RuntimeConfigType.makeClient(
            httpClientConfiguration: config ?? RuntimeConfigType.defaultHttpClientConfiguration
        )
    }

    /// Returns default `HttpClientConfiguration`.
    open class func httpClientConfiguration() -> HttpClientConfiguration {
        return RuntimeConfigType.defaultHttpClientConfiguration
    }

    /// Returns a default idempotency token generator.
    open class func idempotencyTokenGenerator() -> IdempotencyTokenGenerator {
        return RuntimeConfigType.defaultIdempotencyTokenGenerator
    }

    /// Returns a default client logging mode.
    open class func clientLogMode() -> ClientLogMode {
        return RuntimeConfigType.defaultClientLogMode
    }

    /// Returns default retry strategy options.
    public static func backoffRetryStrategyOptions(
        _ maxAttempts: Int? = nil
    ) throws -> RetryStrategyOptions {
        // Provide standard exponential backoff
        let attempts = maxAttempts ?? 3
        return RetryStrategyOptions(
            backoffStrategy: ExponentialBackoffStrategy(),
            maxRetriesBase: attempts - 1,
            rateLimitingMode: .standard
        )
    }
}
