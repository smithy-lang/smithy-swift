//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime
@testable import SmithyRetries

final class RetryQuotaTests: XCTestCase {

    // MARK: - on creation

    func test_retryQuota_isCreatedWithMaxAndAvailableCapacitySetToInitial() async throws {
        let subject = RetryQuota(availableCapacity: 500, maxCapacity: 500)
        let maxCapacity = await subject.maxCapacity
        let availableCapacity = await subject.availableCapacity
        XCTAssertEqual(maxCapacity, RetryQuota.initialRetryTokens)
        XCTAssertEqual(availableCapacity, RetryQuota.initialRetryTokens)
    }

    // MARK: - hasRetryQuota (SEP 2.1: isThrottling parameter)

    func test_hasRetryQuota_subtractsRetryCostOnNonThrottling() async throws {
        let subject = RetryQuota(availableCapacity: 500, maxCapacity: 500)
        let initialCapacity = await subject.availableCapacity
        _ = await subject.hasRetryQuota(isThrottling: false)
        let finalCapacity = await subject.availableCapacity
        let expectedFinalCapacity = initialCapacity - RetryQuota.retryCost
        XCTAssertEqual(finalCapacity, expectedFinalCapacity)
    }

    func test_hasRetryQuota_returnsRetryCostOnNonThrottling() async throws {
        let subject = RetryQuota(availableCapacity: 500, maxCapacity: 500)
        let capacityAmount = await subject.hasRetryQuota(isThrottling: false)
        XCTAssertEqual(capacityAmount, RetryQuota.retryCost)
    }

    func test_hasRetryQuota_subtractsThrottlingRetryCostOnThrottling() async throws {
        let subject = RetryQuota(availableCapacity: 500, maxCapacity: 500)
        let initialCapacity = await subject.availableCapacity
        _ = await subject.hasRetryQuota(isThrottling: true)
        let finalCapacity = await subject.availableCapacity
        let expectedFinalCapacity = initialCapacity - RetryQuota.throttlingRetryCost
        XCTAssertEqual(finalCapacity, expectedFinalCapacity)
    }

    func test_hasRetryQuota_returnsThrottlingRetryCostOnThrottling() async throws {
        let subject = RetryQuota(availableCapacity: 500, maxCapacity: 500)
        let capacityAmount = await subject.hasRetryQuota(isThrottling: true)
        XCTAssertEqual(capacityAmount, RetryQuota.throttlingRetryCost)
    }

    func test_hasRetryQuota_returnsNilWhenRetryCostNotAvailable() async throws {
        let subject = RetryQuota(availableCapacity: RetryQuota.retryCost - 1, maxCapacity: 500)
        let capacityAmount = await subject.hasRetryQuota(isThrottling: false)
        XCTAssertNil(capacityAmount)
    }

    func test_hasRetryQuota_doesNotChangeAvailableCapacityWhenRetryCostNotAvailable() async throws {
        let initialCapacity = RetryQuota.retryCost - 1
        let subject = RetryQuota(availableCapacity: initialCapacity, maxCapacity: 500)
        _ = await subject.hasRetryQuota(isThrottling: false)
        let finalCapacity = await subject.availableCapacity
        XCTAssertEqual(initialCapacity, finalCapacity)
    }

    // MARK: - SEP 2.1 constant values

    func test_retryCost_is14() {
        XCTAssertEqual(RetryQuota.retryCost, 14)
    }

    func test_throttlingRetryCost_is5() {
        XCTAssertEqual(RetryQuota.throttlingRetryCost, 5)
    }

    func test_initialRetryTokens_is500() {
        XCTAssertEqual(RetryQuota.initialRetryTokens, 500)
    }

    func test_noRetryIncrement_is1() {
        XCTAssertEqual(RetryQuota.noRetryIncrement, 1)
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

    // MARK: - SEP 2.1: Verify quota after non-throttling retry

    func test_quotaAfterOneNonThrottlingRetry_is486() async throws {
        let subject = RetryQuota(availableCapacity: 500, maxCapacity: 500)
        _ = await subject.hasRetryQuota(isThrottling: false)
        let finalCapacity = await subject.availableCapacity
        XCTAssertEqual(finalCapacity, 486)  // 500 - 14
    }

    func test_quotaAfterOneThrottlingRetry_is495() async throws {
        let subject = RetryQuota(availableCapacity: 500, maxCapacity: 500)
        _ = await subject.hasRetryQuota(isThrottling: true)
        let finalCapacity = await subject.availableCapacity
        XCTAssertEqual(finalCapacity, 495)  // 500 - 5
    }
}
