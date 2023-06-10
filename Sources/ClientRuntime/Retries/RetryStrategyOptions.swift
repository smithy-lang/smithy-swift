//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct RetryStrategyOptions {
    public static var `default` = RetryStrategyOptions(backoffStrategy: ExponentialBackoffStrategy.default, maxRetriesBase: 2)

    /// The backoff strategy determines the number of seconds to wait before retrying a failed operation.
    public let backoffStrategy: RetryBackoffStrategy

    /// This is more of a hint since a custom retry strategy could be aware of certain operational contexts ("partition fail over")
    public let maxRetriesBase: Int

    /// Sets the initial available capacity for this retry strategy's quotas.
    ///
    /// Used only during testing, production uses the default values.
    let availableCapacity: Int

    /// Sets the maximum capacity for this retry strategy's quotas.
    ///
    /// Used only during testing, production uses the default values.
    let maxCapacity: Int

    init(backoffStrategy: RetryBackoffStrategy, maxRetriesBase: Int, availableCapacity: Int = 500, maxCapacity: Int = 500) {
        self.backoffStrategy = backoffStrategy
        self.maxRetriesBase = maxRetriesBase
        self.availableCapacity = availableCapacity
        self.maxCapacity = maxCapacity
    }
}
