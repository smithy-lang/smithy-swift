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

    private let quotaRepository = RetryQuotaRepository()

    public init(options: RetryStrategyOptions) {
        self.options = options
    }

    public func acquireInitialRetryToken(tokenScope: String) async throws -> DefaultRetryToken {
        let quota = await quotaRepository.quota(partitionID: tokenScope)
        return DefaultRetryToken(quota: quota)
    }

    public func refreshRetryTokenForRetry(tokenToRenew: DefaultRetryToken, errorInfo: RetryErrorInfo) async throws {
        tokenToRenew.retryCount += 1
        if tokenToRenew.retryCount > options.maxRetriesBase {
            throw RetryError.maxAttemptsReached
        }
        if let capacityAmount = await tokenToRenew.quota.hasRetryQuota(isTimeout: errorInfo.isTimeout) {
            tokenToRenew.capacityAmount = capacityAmount
        } else {
            throw RetryError.insufficientQuotaRemaining
        }
    }

    public func recordSuccess(token: DefaultRetryToken) async {
        await token.quota.retryQuotaRelease(isSuccess: true, capacityAmount: token.capacityAmount)
    }
}

enum RetryError: Error {
    case maxAttemptsReached
    case insufficientQuotaRemaining
}
