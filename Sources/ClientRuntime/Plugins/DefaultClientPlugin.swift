//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyRetries.DefaultRetryStrategy

public class DefaultClientPlugin<Config: DefaultClientConfiguration & DefaultHttpClientConfiguration>: Plugin {
    typealias DefaultRuntimeConfig = DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>

    public init() {}

    public func configureClient(clientConfiguration: inout Config) async throws {
        clientConfiguration.retryStrategyOptions = DefaultRuntimeConfig.defaultRetryStrategyOptions
        let httpClientConfiguration = DefaultRuntimeConfig .defaultHttpClientConfiguration
        clientConfiguration.httpClientConfiguration = httpClientConfiguration
        clientConfiguration.httpClientEngine = DefaultRuntimeConfig.makeClient(
            httpClientConfiguration: httpClientConfiguration
        )
    }
}
