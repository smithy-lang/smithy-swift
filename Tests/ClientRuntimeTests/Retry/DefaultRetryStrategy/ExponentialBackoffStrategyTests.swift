//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime

final class ExponentialBackoffStrategyTests: XCTestCase {
    private var subject: ExponentialBackoffStrategy!

    override func setUp() {
        subject = ExponentialBackoffStrategy()
        // Randomization is disabled to allow easy, repeatable verification of basic behavior.
        subject.random = { 1.0 }
    }

    func test_backoffStrategy_multipliesByBackoffFactor() {
        subject.random = { 0.25 }
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 0), 0.25)
        subject.random = { 0.5 }
        XCTAssertEqual(subject.computeNextBackoffDelay(attempt: 0), 0.5)
        subject.random = { 0.75 }
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
}
