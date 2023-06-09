//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Keeps the retry quota count.
///
/// Is shared across all requests with the same partition ID.
final actor RetryQuota {
    static var initialRetryTokens: Int { 500 }
    static var retryCost: Int { 5 }
    static var noRetryIncrement: Int { 1 }
    static var timeoutRetryCost: Int { 10 }

    var maxCapacity: Int
    var availableCapacity: Int

    func setAvailableCapacity(_ availableCapacity: Int) { self.availableCapacity = availableCapacity }

    init(availableCapacity: Int = RetryQuota.initialRetryTokens) {
        self.maxCapacity = Self.initialRetryTokens
        self.availableCapacity = availableCapacity
    }

    func hasRetryQuota(isTimeout: Bool) -> Int? {
        let capacityAmount = isTimeout ? Self.timeoutRetryCost : Self.retryCost
        if capacityAmount > availableCapacity { return nil }
        availableCapacity -= capacityAmount
        return capacityAmount
    }

    func retryQuotaRelease(isSuccess: Bool, capacityAmount: Int?) {
        guard isSuccess else { return }
        availableCapacity += capacityAmount ?? Self.noRetryIncrement
        availableCapacity = min(availableCapacity, maxCapacity)
    }
}
