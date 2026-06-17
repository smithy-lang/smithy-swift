//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval
import enum SmithyRetriesAPI.RetryError
import struct SmithyRetriesAPI.RetryErrorInfo
import enum SmithyRetriesAPI.RetryErrorType
import protocol SmithyRetriesAPI.RetryStrategy
import struct SmithyRetriesAPI.RetryStrategyOptions

public struct DefaultRetryStrategy: RetryStrategy, Sendable {
    public typealias Token = DefaultRetryToken

    let options: RetryStrategyOptions

    let quotaRepository: RetryQuotaRepository

    /// Used to inject a mock during unit tests that simulates sleeping.
    /// The default `sleeper` function actually sleeps asynchronously.
    var sleeper: @Sendable (TimeInterval) async throws -> Void = { delay in
        guard delay > 0.0 else { return }
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000.0))
    }

    public init(options: RetryStrategyOptions) {
        self.options = options
        self.quotaRepository = RetryQuotaRepository(options: options)
    }

    public func acquireInitialRetryToken(tokenScope: String) async throws -> DefaultRetryToken {
        let quota = await quotaRepository.quota(partitionID: tokenScope)
        try await acquireSendToken(quota: quota)
        return DefaultRetryToken(quota: quota)
    }

    /// Acquires one client-side rate-limiting send token, sleeping and
    /// re-checking until one is granted. Returns immediately in non-adaptive
    /// mode.
    private func acquireSendToken(quota: RetryQuota) async throws {
        while let wait = await quota.trySendToken() {
            try await sleeper(wait)
        }
    }

    static func baseMultiplier(for errorInfo: RetryErrorInfo) -> TimeInterval {
        if errorInfo.errorType == .throttling {
            return 1.0
        }
        return errorInfo.backoffMultiplier ?? 0.05
    }

    public func refreshRetryTokenForRetry(tokenToRenew: DefaultRetryToken, errorInfo: RetryErrorInfo) async throws {
        let backoffDelay: TimeInterval
        if options.useNewRetries2026 {
            let multiplier = Self.baseMultiplier(for: errorInfo)
            let exponentialBackoff = options.backoffStrategy.computeNextBackoffDelay(
                attempt: tokenToRenew.retryCount, baseMultiplier: multiplier
            )
            // Bound retry-after to [t_i, 5 + t_i] of the exponential backoff.
            if let retryAfterHint = errorInfo.retryAfterHint {
                backoffDelay = min(max(retryAfterHint, exponentialBackoff), 5.0 + exponentialBackoff)
            } else {
                backoffDelay = exponentialBackoff
            }
        } else {
            backoffDelay = errorInfo.retryAfterHint ??
                options.backoffStrategy.computeNextBackoffDelay(attempt: tokenToRenew.retryCount)
        }

        tokenToRenew.retryCount += 1
        if tokenToRenew.retryCount > options.maxRetriesBase {
            throw RetryError.maxAttemptsReached
        }
        if let capacityAmount = await tokenToRenew.quota.hasRetryQuota(errorInfo: errorInfo) {
            tokenToRenew.capacityAmount = capacityAmount
        } else {
            throw Error.insufficientQuota
        }
        let isThrottling = errorInfo.errorType == .throttling
        await tokenToRenew.quota.updateClientSendingRate(isThrottling: isThrottling)
        try await sleeper(backoffDelay)
        try await acquireSendToken(quota: tokenToRenew.quota)
    }

    public func recordSuccess(token: DefaultRetryToken) async {
        await token.quota.retryQuotaRelease(isSuccess: true, capacityAmount: token.capacityAmount)
        await token.quota.updateClientSendingRate(isThrottling: false)
    }
}
