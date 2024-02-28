//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public class DefaultClientPlugin: Plugin {
    public init() {}
    public func configureClient(clientConfiguration: ClientConfiguration) {
        if var config = clientConfiguration as? DefaultClientConfiguration {
            // Populate default values for configuration here if they are missing
            config.retryStrategyOptions =
                DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>
                    .defaultRetryStrategyOptions
        }
    }
}
