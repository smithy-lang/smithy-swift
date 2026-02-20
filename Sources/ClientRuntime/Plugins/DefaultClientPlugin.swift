//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyRetries.DefaultRetryStrategy

public class DefaultClientPlugin: Plugin {

    public init() {}

    public func configureClient<Config: ClientConfiguration>(clientConfiguration: inout Config) async throws {
        guard var config = clientConfiguration as? any DefaultClientConfiguration else { return }
        config.retryStrategyOptions =
            DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>
                .defaultRetryStrategyOptions

        guard var config2 = config as? any DefaultHttpClientConfiguration else { return }
        let httpClientConfiguration =
            DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>
                .defaultHttpClientConfiguration
        config2.httpClientConfiguration = httpClientConfiguration
        config2.httpClientEngine =
            DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>
                .makeClient(httpClientConfiguration: httpClientConfiguration)

        guard let modifiedConfig = config2 as? Config else { return }
        clientConfiguration = modifiedConfig
    }
}
