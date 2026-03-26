//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import SmithyRetriesAPI
@testable import SmithyRetries
@testable import ClientRuntime

final class DefaultRetryStrategyTests: XCTestCase {
    private let scope1 = "scope1"
    private let scope2 = "scope2"
    // SEP 2.1: Non-throttling error info (uses RETRY_COST=14, backoff x=0.05)
    private let retryableInfo = RetryErrorInfo(errorType: .serverError, retryAfterHint: nil, isTimeout: false)
    // SEP 2.1: Throttling error info (uses THROTTLING_RETRY_COST=5, backoff x=1.0)
    private let retryableThrottlingInfo = RetryErrorInfo(errorType: .throttling, retryAfterHint: nil, isTimeout: false)
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
        backoffStrategy.random = { @Sendable () -> Double in 1.0 }
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

    func test_refresh_setsCapacityAmountOnTokenToThrottlingRetryCost() async throws {
        let token1 = try await subject.acquireInitialRetryToken(tokenScope: scope1)
        try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: retryableThrottlingInfo)
        XCTAssertEqual(token1.capacityAmount, RetryQuota.throttlingRetryCost)
    }

    // SEP 2.1: Non-throttling backoff uses x=0.05, so delays are 0.05, 0.1
    func test_refresh_sleepsForExpectedPeriodOnNonThrottlingRetry() async throws {
        let token1 = try await subject.acquireInitialRetryToken(tokenScope: scope1)
        try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: retryableInfo)
        XCTAssertEqual(actualDelay, 0.05)
        try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: retryableInfo)
        XCTAssertEqual(actualDelay, 0.1)
    }

    // SEP 2.1: Throttling backoff uses x=1.0, so delays are 1.0, 2.0
    func test_refresh_sleepsForExpectedPeriodOnThrottlingRetry() async throws {
        let token1 = try await subject.acquireInitialRetryToken(tokenScope: scope1)
        try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: retryableThrottlingInfo)
        XCTAssertEqual(actualDelay, 1.0)
        try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: retryableThrottlingInfo)
        XCTAssertEqual(actualDelay, 2.0)
    }

    // SEP 2.1: retryAfterHint is bounded by [t_i, 5+t_i]
    func test_refresh_sleepsForTheRetryHintDelayWhenProvided() async throws {
        let token1 = try await subject.acquireInitialRetryToken(tokenScope: scope1)
        try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: retryableInfoWithHint)
        // retryAfterHint=0.44, t_i=0.05, so delay = max(0.44, 0.05) = 0.44
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
        } catch DefaultRetryStrategy.Error.insufficientQuota {
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

    // MARK: - SEP 2.1: baseMultiplier

    func test_baseMultiplier_throttling_is1() {
        let info = RetryErrorInfo(errorType: .throttling, retryAfterHint: nil, isTimeout: false)
        XCTAssertEqual(DefaultRetryStrategy.baseMultiplier(for: info), 1.0)
    }

    func test_baseMultiplier_nonThrottling_is005() {
        let info = RetryErrorInfo(errorType: .serverError, retryAfterHint: nil, isTimeout: false)
        XCTAssertEqual(DefaultRetryStrategy.baseMultiplier(for: info), 0.05)
    }

    func test_baseMultiplier_dynamoDB_is0025() {
        let info = RetryErrorInfo(errorType: .serverError, retryAfterHint: nil, isTimeout: false, backoffMultiplier: 0.025)
        XCTAssertEqual(DefaultRetryStrategy.baseMultiplier(for: info), 0.025)
    }

    // MARK: - SEP 2.1: x-amz-retry-after bounds

    func test_retryAfterHint_bounded_byMinimum() async throws {
        // retryAfterHint=0.01 < t_i=0.05, so delay should be 0.05
        let info = RetryErrorInfo(errorType: .serverError, retryAfterHint: 0.01, isTimeout: false)
        let token1 = try await subject.acquireInitialRetryToken(tokenScope: scope1)
        try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: info)
        XCTAssertEqual(actualDelay, 0.05)
    }

    func test_retryAfterHint_bounded_byMaximum() async throws {
        // retryAfterHint=10.0 > 5+t_i=5.05, so delay should be 5.05
        let info = RetryErrorInfo(errorType: .serverError, retryAfterHint: 10.0, isTimeout: false)
        let token1 = try await subject.acquireInitialRetryToken(tokenScope: scope1)
        try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: info)
        XCTAssertEqual(actualDelay, 5.05)
    }

    func test_retryAfterHint_withinBounds_usedAsIs() async throws {
        // retryAfterHint=1.5, t_i=0.05, 5+t_i=5.05, so delay should be 1.5
        let info = RetryErrorInfo(errorType: .serverError, retryAfterHint: 1.5, isTimeout: false)
        let token1 = try await subject.acquireInitialRetryToken(tokenScope: scope1)
        try await subject.refreshRetryTokenForRetry(tokenToRenew: token1, errorInfo: info)
        XCTAssertEqual(actualDelay, 1.5)
    }
}
