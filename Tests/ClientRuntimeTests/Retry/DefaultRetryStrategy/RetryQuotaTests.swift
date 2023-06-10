//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime

class RetryQuotaTests: XCTestCase {

    // MARK: - on creation

    func test_retryQuota_isCreatedWithMaxAndAvailableCapacitySetToInitial() async throws {
        let subject = RetryQuota(availableCapacity: 500, maxCapacity: 500)
        let maxCapacity = await subject.maxCapacity
        let availableCapacity = await subject.availableCapacity
        XCTAssertEqual(maxCapacity, RetryQuota.initialRetryTokens)
        XCTAssertEqual(availableCapacity, RetryQuota.initialRetryTokens)
    }

    // MARK: - hasRetryQuota

    func test_hasRetryQuota_subtractsRetryCostOnNoTimeout() async throws {
        let subject = RetryQuota(availableCapacity: 500, maxCapacity: 500)
        let initialCapacity = await subject.availableCapacity
        _ = await subject.hasRetryQuota(isTimeout: false)
        let finalCapacity = await subject.availableCapacity
        let expectedFinalCapacity = initialCapacity - RetryQuota.retryCost
        XCTAssertEqual(finalCapacity, expectedFinalCapacity)
    }

    func test_hasRetryQuota_returnsRetryCostOnNoTimeout() async throws {
        let subject = RetryQuota(availableCapacity: 500, maxCapacity: 500)
        let capacityAmount = await subject.hasRetryQuota(isTimeout: false)
        XCTAssertEqual(capacityAmount, RetryQuota.retryCost)
    }

    func test_hasRetryQuota_subtractsTimeoutRetryCostOnTimeout() async throws {
        let subject = RetryQuota(availableCapacity: 500, maxCapacity: 500)
        let initialCapacity = await subject.availableCapacity
        _ = await subject.hasRetryQuota(isTimeout: true)
        let finalCapacity = await subject.availableCapacity
        let expectedFinalCapacity = initialCapacity - RetryQuota.timeoutRetryCost
        XCTAssertEqual(finalCapacity, expectedFinalCapacity)
    }

    func test_hasRetryQuota_returnsTimeoutRetryCostOnTimeout() async throws {
        let subject = RetryQuota(availableCapacity: 500, maxCapacity: 500)
        let capacityAmount = await subject.hasRetryQuota(isTimeout: true)
        XCTAssertEqual(capacityAmount, RetryQuota.timeoutRetryCost)
    }

    func test_hasRetryQuota_returnsNilWhenRetryCostNotAvailable() async throws {
        let subject = RetryQuota(availableCapacity: RetryQuota.retryCost - 1, maxCapacity: 500)
        let capacityAmount = await subject.hasRetryQuota(isTimeout: false)
        XCTAssertNil(capacityAmount)
    }

    func test_hasRetryQuota_doesNotChangeAvailableCapacityWhenRetryCostNotAvailable() async throws {
        let initialCapacity = RetryQuota.retryCost - 1
        let subject = RetryQuota(availableCapacity: initialCapacity, maxCapacity: 500)
        _ = await subject.hasRetryQuota(isTimeout: false)
        let finalCapacity = await subject.availableCapacity
        XCTAssertEqual(initialCapacity, finalCapacity)
    }

    // MARK: - retryQuotaRelease

    func test_retryQuotaRelease_addsTheNoRetryIncrementOnSuccessWithNoRetry() async throws {
        let initialCapacity = 250
        let subject = RetryQuota(availableCapacity: initialCapacity, maxCapacity: 500)
        await subject.retryQuotaRelease(isSuccess: true, capacityAmount: nil)
        let finalCapacity = await subject.availableCapacity
        let expectedFinalCapacity = initialCapacity + RetryQuota.noRetryIncrement
        XCTAssertEqual(finalCapacity, expectedFinalCapacity)
    }

    func test_retryQuotaRelease_addsTheCapacityAmountOnSuccessWithPreviousRetry() async throws {
        let initialCapacity = 250
        let subject = RetryQuota(availableCapacity: initialCapacity, maxCapacity: 500)
        await subject.retryQuotaRelease(isSuccess: true, capacityAmount: RetryQuota.retryCost)
        let finalCapacity = await subject.availableCapacity
        let expectedFinalCapacity = initialCapacity + RetryQuota.retryCost
        XCTAssertEqual(finalCapacity, expectedFinalCapacity)
    }

    func test_retryQuotaRelease_addsNoMoreThanMaxCapacity() async throws {
        let initialCapacity = 499
        let subject = RetryQuota(availableCapacity: initialCapacity, maxCapacity: 500)
        await subject.retryQuotaRelease(isSuccess: true, capacityAmount: RetryQuota.retryCost)
        let finalCapacity = await subject.availableCapacity
        let expectedFinalCapacity = await subject.maxCapacity
        XCTAssertEqual(finalCapacity, expectedFinalCapacity)
    }
}
