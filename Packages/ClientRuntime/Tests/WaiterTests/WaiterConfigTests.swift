//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime

fileprivate typealias Acceptor = WaiterConfig<String, String>.Acceptor

class WaiterConfigTests: XCTestCase {
    private let acceptors = [Acceptor(state: .success, matcher: { _, _ in return true })]

    func test_init_minDelayDefaultsTo2WhenNotGiven() async throws {
        let subject = try WaiterConfig(minDelay: nil, maxDelay: nil, acceptors: acceptors)
        XCTAssertEqual(subject.minDelay, 2.0)
    }

    func test_init_maxDelayDefaultsTo120WhenNotGiven() async throws {
        let subject = try WaiterConfig(minDelay: nil, maxDelay: nil, acceptors: acceptors)
        XCTAssertEqual(subject.maxDelay, 120.0)
    }

    func test_init_throwsWhenAcceptorsDoesNotContainSuccessState() async throws {
        let badAcceptors = [Acceptor(state: .retry, matcher: { _, _ in return true })]
        XCTAssertThrowsError(try WaiterConfig(minDelay: nil, maxDelay: nil, acceptors: badAcceptors)) { error in
            XCTAssert(error is WaiterConfigError)
        }
    }

    func test_init_throwsWhenAcceptorsIsEmpty() async throws {
        let noAcceptors = [Acceptor]()
        XCTAssertThrowsError(try WaiterConfig(minDelay: nil, maxDelay: nil, acceptors: noAcceptors)) { error in
            XCTAssert(error is WaiterConfigError)
        }
    }
}
