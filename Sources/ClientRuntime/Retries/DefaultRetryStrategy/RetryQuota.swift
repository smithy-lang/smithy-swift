//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

/// Keeps the retry quota count for one partition ID.
///
/// Is shared across all requests with the same partition ID; typically this also correlates to one network connection.
final actor RetryQuota {

    /// The number of tokens that a quota is created with.
    /// The quota's available capacity may never exceed this number.
    static var initialRetryTokens: Int { 500 }

    /// The number of tokens to be removed for a standard (i.e. non-timeout) retry.
    static var retryCost: Int { 5 }

    /// The number of tokens to be added to the available number for a request that does not need a retry.
    static var noRetryIncrement: Int { 1 }

    /// The number of tokens to be removed for a retry of a timeout error.
    static var timeoutRetryCost: Int { 10 }

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
    /// - Parameters:
    ///   - availableCapacity: The number of tokens in this quota at creation.
    ///   - maxCapacity: <#maxCapacity description#>
    ///   - rateLimitingMode: <#rateLimitingMode description#>
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
    /// - Parameter options: The retry strategy options from which to configure this retry quota
    init(options: RetryStrategyOptions) {
        self.init(
            availableCapacity: options.availableCapacity,
            maxCapacity: options.maxCapacity,
            rateLimitingMode: options.rateLimitingMode
        )
    }

    /// Deducts the proper number of tokens from available & returns them.
    /// If the number of tokens needed aren't available, `nil` is returned.
    /// - Parameter isTimeout: `true` if the retry being deducted is a timeout error, `false` otherwise.
    /// - Returns: The number of tokens deducted from available capacity, or `nil` if insufficient tokens were available.
    func hasRetryQuota(isTimeout: Bool) -> Int? {
        let capacityAmount = isTimeout ? Self.timeoutRetryCost : Self.retryCost
        if capacityAmount > availableCapacity { return nil }
        availableCapacity -= capacityAmount
        return capacityAmount
    }

    /// Returns tokens to available capacity after a request is successfully completed.
    /// - Parameters:
    ///   - isSuccess: `true` if the request was completed successfully, `false` otherwise.
    ///   - capacityAmount: The number to be added back to capacity.  Will be `nil` when no retry was needed.
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
