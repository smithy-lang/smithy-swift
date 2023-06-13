//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct RetryStrategyOptions {

    /// The backoff strategy determines the number of seconds to wait before retrying a failed operation.
    public let backoffStrategy: RetryBackoffStrategy

    /// This is more of a hint since a custom retry strategy could be aware of certain operational contexts ("partition fail over")
    public let maxRetriesBase: Int

    /// Sets the mode used for rate limiting initial requests.
    public enum RateLimitingMode {

        /// Initial requests may be sent immediately.
        ///
        /// This is default retry behavior.
        case standard

        /// Initial requests may be delayed when throttling is detected.
        ///
        /// This is sometimes called "adaptive" or "client-side rate limiting" mode, and is available opt-in.
        case adaptive
    }

    /// The mode to be used for rate-limiting initial requests.
    ///
    /// In `standard` mode, initial requests are never delayed.  In `adaptive` mode, initial requests are
    /// delayed when the server indicates that requests are being throttled.
    public let rateLimitingMode: RateLimitingMode

    /// Sets the initial available capacity for this retry strategy's quotas.
    ///
    /// Used only during testing, production uses the default values.
    let availableCapacity: Int

    /// Sets the maximum capacity for this retry strategy's quotas.
    ///
    /// Used only during testing, production uses the default values.
    let maxCapacity: Int

    /// Creates a new set of retry strategy options
    /// - Parameters:
    ///   - backoffStrategy: Determines the delay time before retrying.  Defaults to exponential backoff with a max limit.
    ///   - maxRetriesBase: The number of times to retry the initial request.  Defaults to 2.
    ///   - availableCapacity: The number of available tokens in a retry quota.  Defaults to 500.
    ///   - maxCapacity: The max number of tokens in a retry quota.  Defaults to 500.
    init(
        backoffStrategy: RetryBackoffStrategy = ExponentialBackoffStrategy(),
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
