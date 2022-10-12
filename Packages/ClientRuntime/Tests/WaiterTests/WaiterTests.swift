//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime

class WaiterTests: XCTestCase {

    // MARK: - asyncSequence()

    func test_asyncSequence_returnsAConfiguredSequence() async throws {
        let minDelay = TimeInterval.random(in: 2.0...10.0)
        let maxDelay = TimeInterval.random(in: 20.0...30.0)
        let maximumWaitTime = TimeInterval.random(in: 60.0...120.0)
        let waiter = Waiter<String, String>(input: "input", acceptors: [], minDelay: minDelay, maxDelay: maxDelay, maximumWaitTime: maximumWaitTime, operation: { _ in return "output" })
        let sequence = waiter.asyncSequence()
        XCTAssertIdentical(sequence.waiter, waiter)
        let iterator = sequence.makeAsyncIterator()
        XCTAssertEqual(iterator.scheduler.minDelay, minDelay)
        XCTAssertEqual(iterator.scheduler.maxDelay, maxDelay)
        XCTAssertEqual(iterator.scheduler.maximumWaitTime, maximumWaitTime)
    }
}
