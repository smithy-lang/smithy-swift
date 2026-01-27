//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyRetries.DefaultRetryStrategy

public class DefaultClientPlugin: Plugin {
    public init() {}
    public func configureClient(clientConfiguration: inout ClientConfiguration) async throws {
        if var config = clientConfiguration as? any DefaultClientConfiguration {
            config.retryStrategyOptions =
                DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>
                    .defaultRetryStrategyOptions
            clientConfiguration = config
        }

        if var config = clientConfiguration as? any DefaultHttpClientConfiguration {
            let httpClientConfiguration =
                DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>
                    .defaultHttpClientConfiguration
            config.httpClientConfiguration = httpClientConfiguration
            config.httpClientEngine =
                DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>
                    .makeClient(httpClientConfiguration: httpClientConfiguration)
            clientConfiguration = config
        }
    }
}
