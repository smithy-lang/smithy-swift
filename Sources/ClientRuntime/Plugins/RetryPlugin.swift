//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyRetriesAPI.RetryStrategyOptions

public class RetryPlugin: Plugin {

    private var retryStrategyOptions: RetryStrategyOptions

    public init(retryStrategyOptions: RetryStrategyOptions) {
        self.retryStrategyOptions = retryStrategyOptions
    }

    public func configureClient(clientConfiguration: ClientConfiguration) async throws -> ClientConfiguration {
        // Since configurations are now immutable structs, we can't mutate them.
        // The retry strategy options are already set in the configuration's initializer,
        // so this plugin doesn't need to do anything.
        return clientConfiguration
    }
}
