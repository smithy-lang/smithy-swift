//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import SmithyRetries
@testable import ClientRuntime

final class ExponentialBackoffStrategyTests: XCTestCase {
    private var subject: ExponentialBackoffStrategy!

    override func setUp() {
        subject = ExponentialBackoffStrategy()
        subject.random = { @Sendable () -> Double in 1.0 }
    }

    func test_backoffStrategy_multipliesByBackoffFactor() {
        subject.random = { @Sendable () -> Double in 0.25 }
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 0), 0.25)
        subject.random = { @Sendable () -> Double in 0.5 }
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 0), 0.5)
        subject.random = { @Sendable () -> Double in 0.75 }
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 0), 0.75)
    }

    func test_backoffStrategy_backsOffExponentially() {
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 0), 1.0)
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 1), 2.0)
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 2), 4.0)
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 3), 8.0)
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 4), 16.0)
    }

    func test_backoffStrategy_backoffTopsOutAtMaxBackoff() {
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 5), 20.0)
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 6), 20.0)
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 7), 20.0)
    }

    // MARK: - Variable base multiplier

    func test_backoffWithMultiplier_nonThrottling() {
        // x=0.05: delays are 0.05, 0.1, 0.2, 0.4, 0.8, 1.6, ...
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 0, baseMultiplier: 0.05), 0.05)
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 1, baseMultiplier: 0.05), 0.1)
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 2, baseMultiplier: 0.05), 0.2)
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 3, baseMultiplier: 0.05), 0.4)
    }

    func test_backoffWithMultiplier_dynamoDB() {
        // x=0.025: delays are 0.025, 0.05, 0.1, 0.2, ...
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 0, baseMultiplier: 0.025), 0.025)
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 1, baseMultiplier: 0.025), 0.05)
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 2, baseMultiplier: 0.025), 0.1)
    }

    func test_backoffWithMultiplier_throttling() {
        // x=1.0: same as original behavior
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 0, baseMultiplier: 1.0), 1.0)
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 1, baseMultiplier: 1.0), 2.0)
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 2, baseMultiplier: 1.0), 4.0)
    }

    func test_backoffWithMultiplier_capsAtMaxBackoff() {
        // x=0.05, attempt=20: 0.05 * 2^20 = 52428.8, capped at 20.0
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 20, baseMultiplier: 0.05), 20.0)
    }
}
