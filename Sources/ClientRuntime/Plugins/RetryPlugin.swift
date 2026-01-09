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

    public func configureClient(clientConfiguration: inout ClientConfiguration) async throws {
        if var config = clientConfiguration as? any DefaultClientConfiguration {
            config.retryStrategyOptions = self.retryStrategyOptions
            clientConfiguration = config as! ClientConfiguration
        }
    }
}
