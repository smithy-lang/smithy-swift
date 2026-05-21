//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct RetryStrategyOptions: Sendable {

    /// The backoff strategy determines the number of seconds to wait before retrying a failed operation.
    public let backoffStrategy: RetryBackoffStrategy

    /// This is more of a hint since a custom retry strategy could be aware of certain operational contexts ("partition fail over")
    public let maxRetriesBase: Int

    /// Sets the mode used for rate limiting requests in response to throttling.
    public enum RateLimitingMode: Sendable {

        /// Requests may be sent immediately, and are not delayed for rate limiting when throttling is detected.
        ///
        /// This is default retry behavior.
        case standard

        /// Initial and retry requests may be delayed by an additional amount when throttling is detected.
        ///
        /// This is sometimes called "adaptive" or "client-side rate limiting" mode, and is available opt-in.
        case adaptive
    }

    /// The mode to be used for rate-limiting requests.
    public let rateLimitingMode: RateLimitingMode

    /// Sets the initial available capacity for this retry strategy's quotas.
    public let availableCapacity: Int

    /// Sets the maximum capacity for this retry strategy's quotas.
    public let maxCapacity: Int

    /// Creates a new set of retry strategy options
    public init(
        backoffStrategy: RetryBackoffStrategy,
        maxRetriesBase: Int = 2,
        availableCapacity: Int = 500,
        maxCapacity: Int = 500,
        rateLimitingMode: RateLimitingMode = .standard
    ) {
        self.backoffStrategy = backoffStrategy
        self.maxRetriesBase = maxRetriesBase
        self.availableCapacity = availableCapacity
        self.maxCapacity = maxCapacity
        self.rateLimitingMode = rateLimitingMode
    }
}
