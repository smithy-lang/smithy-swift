//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A protocol that allows for actual asynchronous sleep when running,
/// and for immediate return with verification of sleep duration in testing.
protocol Sleepable {

    /// Sleeps asynchronously for the duration specified, the resumes asynchronously when the specified delay has passed.
    /// - Parameter nanoseconds: The time to sleep, in nanoseconds.
    func sleep(nanoseconds: UInt64) async throws
}

public struct DefaultRetryStrategy: RetryStrategy {
    public typealias Token = DefaultRetryToken

    let options: RetryStrategyOptions

    let quotaRepository = RetryQuotaRepository()

    /// Used to inject a mock during unit tests that simulates sleeping.
    /// The default `Sleeper` instance actually sleeps asynchronously.
    var sleeper: Sleepable = Sleeper()

    public init(options: RetryStrategyOptions) {
        self.options = options
    }

    public func acquireInitialRetryToken(tokenScope: String) async throws -> DefaultRetryToken {
        let quota = await quotaRepository.quota(partitionID: tokenScope)
        return DefaultRetryToken(quota: quota)
    }

    public func refreshRetryTokenForRetry(tokenToRenew: DefaultRetryToken, errorInfo: RetryErrorInfo) async throws {
        let delay = errorInfo.retryAfterHint ?? options.backoffStrategy.computeNextBackoffDelay(attempt: tokenToRenew.retryCount)
        tokenToRenew.retryCount += 1
        if tokenToRenew.retryCount > options.maxRetriesBase {
            throw RetryError.maxAttemptsReached
        }
        if let capacityAmount = await tokenToRenew.quota.hasRetryQuota(isTimeout: errorInfo.isTimeout) {
            tokenToRenew.capacityAmount = capacityAmount
        } else {
            throw RetryError.insufficientQuota
        }
        let nsDelay = UInt64(delay * 1_000_000_000.0)
        try await sleeper.sleep(nanoseconds: nsDelay)
    }

    public func recordSuccess(token: DefaultRetryToken) async {
        await token.quota.retryQuotaRelease(isSuccess: true, capacityAmount: token.capacityAmount)
    }
}

enum RetryError: Error {
    case maxAttemptsReached
    case insufficientQuota
}

private struct Sleeper: Sleepable {

    func sleep(nanoseconds: UInt64) async throws {
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}
