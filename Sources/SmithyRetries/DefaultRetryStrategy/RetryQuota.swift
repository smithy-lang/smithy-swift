//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval
import struct SmithyRetriesAPI.RetryErrorInfo
import enum SmithyRetriesAPI.RetryErrorType
import struct SmithyRetriesAPI.RetryStrategyOptions

/// Keeps the retry quota count for one partition ID.
///
/// Is shared across all requests with the same partition ID; typically this also correlates to one network connection.
final actor RetryQuota {

    /// The number of tokens that a quota is created with.
    /// The quota's available capacity may never exceed this number.
    static var initialRetryTokens: Int { 500 } // swiftlint:disable:this unused_declaration

    static var retryCost: Int { 14 }
    static var retryCostLegacy: Int { 5 }

    static var noRetryIncrement: Int { 1 }

    static var throttlingRetryCost: Int { 5 }
    static var timeoutRetryCost: Int { 10 }

    /// The maximum number of tokens this quota will hold.  Same as initial capacity.
    var maxCapacity: Int

    /// The number of tokens this quota currently holds.
    var availableCapacity: Int

    /// The rate limiter to be used, if any.
    private var rateLimiter: ClientSideRateLimiter?

    private let useNewRetries2026: Bool

    /// Sets the current capacity in this quota.  To be used for testing only.
    func setAvailableCapacity(_ availableCapacity: Int) { // swiftlint:disable:this unused_declaration
        self.availableCapacity = availableCapacity
    }

    init(
        availableCapacity: Int,
        maxCapacity: Int,
        rateLimitingMode: RetryStrategyOptions.RateLimitingMode = .standard,
        useNewRetries2026: Bool = false
    ) {
        self.availableCapacity = availableCapacity
        self.maxCapacity = max(maxCapacity, availableCapacity)
        self.rateLimiter = rateLimitingMode == .adaptive ? ClientSideRateLimiter() : nil
        self.useNewRetries2026 = useNewRetries2026
    }

    init(options: RetryStrategyOptions) {
        self.init(
            availableCapacity: options.availableCapacity,
            maxCapacity: options.maxCapacity,
            rateLimitingMode: options.rateLimitingMode,
            useNewRetries2026: options.useNewRetries2026
        )
    }

    func hasRetryQuota(errorInfo: RetryErrorInfo) -> Int? {
        let capacityAmount: Int
        if useNewRetries2026 {
            let isThrottling = errorInfo.errorType == .throttling
            capacityAmount = isThrottling ? Self.throttlingRetryCost : Self.retryCost
        } else {
            capacityAmount = errorInfo.isTimeout ? Self.timeoutRetryCost : Self.retryCostLegacy
        }
        if capacityAmount > availableCapacity { return nil }
        availableCapacity -= capacityAmount
        return capacityAmount
    }

    func hasRetryQuota(isThrottling: Bool) -> Int? { // swiftlint:disable:this unused_declaration
        let errorType: RetryErrorType = isThrottling ? .throttling : .transient
        return hasRetryQuota(errorInfo: RetryErrorInfo(errorType: errorType, retryAfterHint: nil, isTimeout: false))
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
