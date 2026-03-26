//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval
import struct SmithyRetriesAPI.RetryStrategyOptions

/// Keeps the retry quota count for one partition ID.
///
/// Is shared across all requests with the same partition ID; typically this also correlates to one network connection.
final actor RetryQuota {

    /// The number of tokens that a quota is created with.
    /// The quota's available capacity may never exceed this number.
    static var initialRetryTokens: Int { 500 }

    /// Retries SEP 2.1: The number of tokens to be removed for a non-throttling retry.
    static var retryCost: Int { 14 }

    /// The number of tokens to be added to the available number for a request that does not need a retry.
    static var noRetryIncrement: Int { 1 }

    /// Retries SEP 2.1: The number of tokens to be removed for a retry of a throttling error.
    static var throttlingRetryCost: Int { 5 }

    /// The maximum number of tokens this quota will hold.  Same as initial capacity.
    var maxCapacity: Int

    /// The number of tokens this quota currently holds.
    var availableCapacity: Int

    /// The rate limiter to be used, if any.
    private var rateLimiter: ClientSideRateLimiter?

    /// Sets the current capacity in this quota.  To be used for testing only.
    func setAvailableCapacity(_ availableCapacity: Int) { self.availableCapacity = availableCapacity }

    /// Creates a new quota, optionally with reduced available capacity (used for testing.)
    /// `maxCapacity` cannot be set less than available.
    init(
        availableCapacity: Int,
        maxCapacity: Int,
        rateLimitingMode: RetryStrategyOptions.RateLimitingMode = .standard
    ) {
        self.availableCapacity = availableCapacity
        self.maxCapacity = max(maxCapacity, availableCapacity)
        self.rateLimiter = rateLimitingMode == .adaptive ? ClientSideRateLimiter() : nil
    }

    /// Creates a new quota with settings from the passed options.
    init(options: RetryStrategyOptions) {
        self.init(
            availableCapacity: options.availableCapacity,
            maxCapacity: options.maxCapacity,
            rateLimitingMode: options.rateLimitingMode
        )
    }

    /// Retries SEP 2.1: Deducts the proper number of tokens from available & returns them.
    /// Uses `throttlingRetryCost` for throttling errors, `retryCost` for all others.
    /// - Parameter isThrottling: `true` if the error is a throttling error, `false` otherwise.
    /// - Returns: The number of tokens deducted, or `nil` if insufficient tokens were available.
    func hasRetryQuota(isThrottling: Bool) -> Int? {
        let capacityAmount = isThrottling ? Self.throttlingRetryCost : Self.retryCost
        if capacityAmount > availableCapacity { return nil }
        availableCapacity -= capacityAmount
        return capacityAmount
    }

    /// Returns tokens to available capacity after a request is successfully completed.
    func retryQuotaRelease(isSuccess: Bool, capacityAmount: Int?) {
        guard isSuccess else { return }
        availableCapacity += capacityAmount ?? Self.noRetryIncrement
        availableCapacity = min(availableCapacity, maxCapacity)
    }

    func getRateLimitDelay() async -> TimeInterval {
        await rateLimiter?.tokenBucketAcquire(amount: 1.0) ?? 0.0
    }

    func updateClientSendingRate(isThrottling: Bool) async {
        await rateLimiter?.updateClientSendingRate(isThrottling: isThrottling)
    }
}
