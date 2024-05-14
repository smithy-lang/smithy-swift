//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval
import protocol SmithyRetriesAPI.RetryStrategy
import struct SmithyRetriesAPI.RetryStrategyOptions
import struct SmithyRetriesAPI.RetryErrorInfo
import enum SmithyRetriesAPI.RetryError

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

    public func refreshRetryTokenForRetry(tokenToRenew: DefaultRetryToken, errorInfo: RetryErrorInfo) async throws {
        let backoffDelay = errorInfo.retryAfterHint ??
            options.backoffStrategy.computeNextBackoffDelay(attempt: tokenToRenew.retryCount)
        tokenToRenew.retryCount += 1
        if tokenToRenew.retryCount > options.maxRetriesBase {
            throw RetryError.maxAttemptsReached
        }
        if let capacityAmount = await tokenToRenew.quota.hasRetryQuota(isTimeout: errorInfo.isTimeout) {
            tokenToRenew.capacityAmount = capacityAmount
        } else {
            throw Error.insufficientQuota
        }
        let isThrottling = errorInfo.errorType == .throttling
        await tokenToRenew.quota.updateClientSendingRate(isThrottling: isThrottling)
        let rateLimitDelay = await tokenToRenew.quota.getRateLimitDelay()
        try await sleeper(backoffDelay + rateLimitDelay)
    }

    public func recordSuccess(token: DefaultRetryToken) async {
        await token.quota.retryQuotaRelease(isSuccess: true, capacityAmount: token.capacityAmount)
    }
}
