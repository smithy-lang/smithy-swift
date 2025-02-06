//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyRetries.DefaultRetryStrategy

public class DefaultClientPlugin<Config: DefaultClientConfiguration & DefaultHttpClientConfiguration>: Plugin {

    public init() {}

    public func configureClient(clientConfiguration: Config) async throws -> Config {
        var copy = clientConfiguration
        copy.retryStrategyOptions =
            DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>
                .defaultRetryStrategyOptions
        let httpClientConfiguration =
            DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>
                .defaultHttpClientConfiguration
        copy.httpClientConfiguration = httpClientConfiguration
        copy.httpClientEngine =
            DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>
                .makeClient(httpClientConfiguration: httpClientConfiguration)
        return copy
    }
}
