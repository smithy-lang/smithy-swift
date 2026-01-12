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
        guard var config = clientConfiguration as? any DefaultClientConfiguration else { return }
        config.retryStrategyOptions = self.retryStrategyOptions
        clientConfiguration = config
    }
}
