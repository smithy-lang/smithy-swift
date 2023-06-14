//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct DefaultRetryStrategy: RetryStrategy {
    public typealias Token = DefaultRetryToken

    let options: RetryStrategyOptions

    let quotaRepository: RetryQuotaRepository

    /// Used to inject a mock during unit tests that simulates sleeping.
    /// The default `sleeper` function actually sleeps asynchronously.
    var sleeper: (TimeInterval) async throws -> Void = { delay in
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000.0))
    }

    public init(options: RetryStrategyOptions) {
        self.options = options
        self.quotaRepository = RetryQuotaRepository(
            availableCapacity: options.availableCapacity,
            maxCapacity: options.maxCapacity
        )
    }

    public func acquireInitialRetryToken(tokenScope: String) async throws -> DefaultRetryToken {
        let quota = await quotaRepository.quota(partitionID: tokenScope)
        return DefaultRetryToken(quota: quota)
    }

    public func refreshRetryTokenForRetry(tokenToRenew: DefaultRetryToken, errorInfo: RetryErrorInfo) async throws {
        let delay = errorInfo.retryAfterHint ??
            options.backoffStrategy.computeNextBackoffDelay(attempt: tokenToRenew.retryCount)
        tokenToRenew.retryCount += 1
        tokenToRenew.delay = delay
        if tokenToRenew.retryCount > options.maxRetriesBase {
            throw RetryError.maxAttemptsReached
        }
        if let capacityAmount = await tokenToRenew.quota.hasRetryQuota(isTimeout: errorInfo.isTimeout) {
            tokenToRenew.capacityAmount = capacityAmount
        } else {
            throw RetryError.insufficientQuota
        }
        try await sleeper(tokenToRenew.delay ?? 0.0)
    }

    public func recordSuccess(token: DefaultRetryToken) async {
        await token.quota.retryQuotaRelease(isSuccess: true, capacityAmount: token.capacityAmount)
    }
}

enum RetryError: Error {
    case maxAttemptsReached
    case insufficientQuota
}
