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

public struct DefaultRetryStrategy: RetryStrategy {
    public typealias Token = DefaultRetryToken

    let options: RetryStrategyOptions

    let quotaRepository: RetryQuotaRepository

    /// Used to inject a mock during unit tests that simulates sleeping.
    /// The default `sleeper` function actually sleeps asynchronously.
    var sleeper: (TimeInterval) async throws -> Void = { delay in
        guard delay > 0.0 else { return }
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000.0))
    }

    public init(options: RetryStrategyOptions) {
        self.options = options
        self.quotaRepository = RetryQuotaRepository(options: options)
    }

    public func acquireInitialRetryToken(tokenScope: String) async throws -> DefaultRetryToken {
        let quota = await quotaRepository.quota(partitionID: tokenScope)
        let rateLimitDelay = await quota.getRateLimitDelay()
        try await sleeper(rateLimitDelay)
        return DefaultRetryToken(quota: quota)
    }

    /// Retries SEP 2.1: Computes the base multiplier `x` for exponential backoff.
    static func baseMultiplier(for errorInfo: RetryErrorInfo) -> TimeInterval {
        if errorInfo.errorType == .throttling {
            return 1.0
        }
        return errorInfo.backoffMultiplier ?? 0.05
    }

    public func refreshRetryTokenForRetry(tokenToRenew: DefaultRetryToken, errorInfo: RetryErrorInfo) async throws {
        let multiplier = Self.baseMultiplier(for: errorInfo)
        let exponentialBackoff = options.backoffStrategy.computeNextBackoffDelay(
            attempt: tokenToRenew.retryCount, baseMultiplier: multiplier
        )

        let backoffDelay: TimeInterval
        if let retryAfterHint = errorInfo.retryAfterHint {
            // Retries SEP 2.1: Apply bounds to x-amz-retry-after value
            // Minimum: t_i (exponential backoff), Maximum: 5 + t_i
            backoffDelay = min(max(retryAfterHint, exponentialBackoff), 5.0 + exponentialBackoff)
        } else {
            backoffDelay = exponentialBackoff
        }

        tokenToRenew.retryCount += 1
        if tokenToRenew.retryCount > options.maxRetriesBase {
            throw RetryError.maxAttemptsReached
        }
        let isThrottling = errorInfo.errorType == .throttling
        if let capacityAmount = await tokenToRenew.quota.hasRetryQuota(isThrottling: isThrottling) {
            tokenToRenew.capacityAmount = capacityAmount
        } else {
            throw Error.insufficientQuota
        }
        await tokenToRenew.quota.updateClientSendingRate(isThrottling: isThrottling)
        let rateLimitDelay = await tokenToRenew.quota.getRateLimitDelay()
        try await sleeper(backoffDelay + rateLimitDelay)
    }

    public func recordSuccess(token: DefaultRetryToken) async {
        await token.quota.retryQuotaRelease(isSuccess: true, capacityAmount: token.capacityAmount)
        await token.quota.updateClientSendingRate(isThrottling: false)
    }
}
