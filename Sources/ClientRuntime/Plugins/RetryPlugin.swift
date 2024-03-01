//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public class RetryPlugin: Plugin {

    private var retryStrategyOptions: RetryStrategyOptions

    public init(retryStrategyOptions: RetryStrategyOptions) {
        self.retryStrategyOptions = retryStrategyOptions
    }

    public func configureClient(clientConfiguration: ClientConfiguration) {
        if var config = clientConfiguration as? DefaultClientConfiguration {
            config.retryStrategyOptions = self.retryStrategyOptions
        }
    }
}
