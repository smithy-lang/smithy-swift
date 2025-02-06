//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyRetriesAPI.RetryStrategyOptions

public class RetryPlugin<Config: DefaultClientConfiguration>: Plugin {

    private var retryStrategyOptions: RetryStrategyOptions

    public init(retryStrategyOptions: RetryStrategyOptions) {
        self.retryStrategyOptions = retryStrategyOptions
    }

    public func configureClient(clientConfiguration: Config) -> Config {
        var copy = clientConfiguration
        copy.retryStrategyOptions = self.retryStrategyOptions
        return copy
    }
}
