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
            guard let updatedConfig = config as? ClientConfiguration else {
                throw ClientError.dataNotFound("Failed to cast DefaultClientConfiguration back to ClientConfiguration")
            }
            clientConfiguration = updatedConfig
        }
    }
}
