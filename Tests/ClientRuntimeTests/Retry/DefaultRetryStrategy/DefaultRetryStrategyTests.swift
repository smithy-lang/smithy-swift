//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime

final class DefaultRetryStrategyTests: XCTestCase {
    private let scope1 = "scope1"
    private let scope2 = "scope2"
    private let retryableInfo = RetryErrorInfo(errorType: .serverError, retryAfterHint: nil, isTimeout: false)
    private let retryableInfoWithTimeout = RetryErrorInfo(errorType: .clientError, retryAfterHint: nil, isTimeout: true)
    private let retryableInfoWithHint = RetryErrorInfo(errorType: .serverError, retryAfterHint: 0.44, isTimeout: false)
    private var quota1: RetryQuota { get async { await subject.quotaRepository.quota(partitionID: scope1) } }
    private var quota2: RetryQuota { get async { await subject.quotaRepository.quota(partitionID: scope2) } }

    private var options: RetryStrategyOptions!
    private var subject: DefaultRetryStrategy!
    private var mockSleeper: ((TimeInterval) async throws -> Void)!
    private var backoffStrategy: ExponentialBackoffStrategy!
    private var actualDelay: TimeInterval = 0.0

    override func setUp() {
        backoffStrategy = .init()
        backoffStrategy.random = { 1.0 }
        options = RetryStrategyOptions(backoffStrategy: backoffStrategy, maxRetriesBase: 2)
        subject = DefaultRetryStrategy(options: options)
        mockSleeper = { self.actualDelay = $0 }
        subject.sleeper = mockSleeper
    }

    // MARK: - acquireInitialRetryToken(tokenScope:)

    func test_acquire_acquiresANewTokenWithZeroRetryCount() async throws {
        let newToken = try await subject.acquireInitialRetryToken(tokenScope: scope1)
        XCTAssertEqual(newToken.retryCount, 0)
    }

    func test_acquire_acquiresANewTokenWithNilCapacityAmount() async throws {
        let newToken = try await subject.acquireInitialRetryToken(tokenScope: scope1)
        XCTAssertEqual(newToken.capacityAmount, nil)
    }

    func test_acquire_quotaCapacityIsUnchangedAfterAcquire() async throws {
        let initialCapacity = await quota1.availableCapacity
        _ = try await subject.acquireInitialRetryToken(tokenScope: scope1)
        let finalCapacity = await quota1.availableCapacity
        XCTAssertEqual(initialCapacity, finalCapacity)
    }

    func test_acquire_acquiresTokensInDifferentScopesAgainstDifferentQuotas() async throws {
        let token1 = try await subject.acquireInitialRetryToken(tokenScope: scope1)
        let token2 = try await subject.acquireInitialRetryToken(tokenScope: scope2)
        XCTAssertFalse(token1.quota === token2.quota)
    }

    // MARK: - refreshRetryTokenForRetry(tokenToRenew:errorInfo:)

    func test_refresh_setsCapacityAmountOnTokenToRetryCost() async throws {
        let token1 = try await subject.acquireInitialRetryToken(tokenScope: scope1)

        try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: retryableInfo)

        XCTAssertEqual(token1.capacityAmount, RetryQuota.retryCost)
    }

    func test_refresh_setsCapacityAmountOnTokenToTimeoutRetryCost() async throws {
        let token1 = try await subject.acquireInitialRetryToken(tokenScope: scope1)

        try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: retryableInfoWithTimeout)

        XCTAssertEqual(token1.capacityAmount, RetryQuota.timeoutRetryCost)
    }

    func test_refresh_sleepsForExpectedPeriodOnRetry() async throws {
        let token1 = try await subject.acquireInitialRetryToken(tokenScope: scope1)

        try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: retryableInfo)
        XCTAssertEqual(actualDelay, 1.0)

        try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: retryableInfo)
        XCTAssertEqual(actualDelay, 2.0)
    }

    func test_refresh_sleepsForTheRetryHintDelayWhenProvided() async throws {
        let token1 = try await subject.acquireInitialRetryToken(tokenScope: scope1)

        try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: retryableInfoWithHint)
        XCTAssertEqual(actualDelay, retryableInfoWithHint.retryAfterHint!)
    }

    func test_refresh_throwsMaxAttemptsReachedWhenMaxAttemptsReached() async throws {
        let token1 = try await subject.acquireInitialRetryToken(tokenScope: scope1)

        for _ in 0..<options.maxRetriesBase {
            try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: retryableInfo)
        }
        do {
            try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: retryableInfo)
            XCTFail("Should have failed")
        } catch RetryError.maxAttemptsReached {
            // success
        } catch {
            XCTFail("Unexpected error thrown")
        }
    }

    func test_refresh_throwsInsufficientQuotaWhenQuotaNotAvailable() async throws {
        await quota1.setAvailableCapacity(RetryQuota.retryCost - 1)
        let token1 = try await subject.acquireInitialRetryToken(tokenScope: scope1)

        do {
            try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: retryableInfo)
            XCTFail("Should have failed")
        } catch RetryError.insufficientQuota {
            // success
        } catch {
            XCTFail("Unexpected error thrown")
        }
    }

    // MARK: - recordSuccess(token:)

    func test_success_addsNoRetryIncrementToCapacityOnSuccessWithNoRetry() async throws {
        let initialCapacity = RetryQuota.initialRetryTokens / 2
        await quota1.setAvailableCapacity(initialCapacity)
        let token = try await subject.acquireInitialRetryToken(tokenScope: scope1)

        await subject.recordSuccess(token: token)
        let finalCapacity = await quota1.availableCapacity

        XCTAssertEqual(initialCapacity + RetryQuota.noRetryIncrement, finalCapacity)
    }

    func test_success_addsCapacityAmountBackToQuotaOnSuccessAfterRetry() async throws {
        let initialCapacity = RetryQuota.initialRetryTokens / 2
        await quota1.setAvailableCapacity(initialCapacity)
        let token = try await subject.acquireInitialRetryToken(tokenScope: scope1)
        try await subject.refreshRetryTokenForRetry(tokenToRenew: token, errorInfo: retryableInfo)

        let tokenCapacityAmount = try XCTUnwrap(token.capacityAmount)
        XCTAssertEqual(tokenCapacityAmount, RetryQuota.retryCost)

        await subject.recordSuccess(token: token)
        let finalCapacity = await quota1.availableCapacity

        XCTAssertEqual(initialCapacity, finalCapacity)
    }
}
