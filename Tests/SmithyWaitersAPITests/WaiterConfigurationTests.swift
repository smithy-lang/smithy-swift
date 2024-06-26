//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import SmithyWaitersAPI

fileprivate typealias Acceptor = WaiterConfiguration<String, String>.Acceptor

class WaiterConfigurationTests: XCTestCase {
    private let acceptors = [Acceptor(state: .success, matcher: { _, _ in return true })]

    func test_init_minDelayDefaultsTo2WhenNotGiven() async throws {
        let subject = try WaiterConfiguration(acceptors: acceptors)
        XCTAssertEqual(subject.minDelay, 2.0)
    }

    func test_init_maxDelayDefaultsTo120WhenNotGiven() async throws {
        let subject = try WaiterConfiguration(acceptors: acceptors)
        XCTAssertEqual(subject.maxDelay, 120.0)
    }

    func test_init_throwsWhenAcceptorsDoesNotContainSuccessState() async throws {
        let badAcceptors = [Acceptor(state: .retry, matcher: { _, _ in return true })]
        XCTAssertThrowsError(try WaiterConfiguration(acceptors: badAcceptors)) { error in
            XCTAssert(error is WaiterConfigurationError)
        }
    }

    func test_init_throwsWhenAcceptorsIsEmpty() async throws {
        let noAcceptors = [Acceptor]()
        XCTAssertThrowsError(try WaiterConfiguration(acceptors: noAcceptors)) { error in
            XCTAssert(error is WaiterConfigurationError)
        }
    }
}
