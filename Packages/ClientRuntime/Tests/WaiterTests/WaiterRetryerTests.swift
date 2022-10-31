//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime

fileprivate typealias Acceptor = WaiterConfiguration<String, String>.Acceptor

class WaiterRetryerTests: XCTestCase {

    fileprivate class Mock {
        var attempt = 0
        var throwsOnOperation = false

        /// Returns or throws "1" the first time it is called, then "2", "3", etc.
        func operation(input: String) async throws -> String {
            attempt += 1
            if throwsOnOperation {
                throw ClientError.unknownError("\(attempt)")
            } else {
                return "\(attempt)"
            }
        }
    }

    func test_waitUntil_throwsWhenFailureIsMatched() async throws {
        let config = try config(failOn: .success("3"))
        let subject = Waiter(config: config, operation: Mock().operation(input:))
        let options = WaiterOptions(maxWaitTime: 120.0)
        await XCTAssertThrowsErrorAsync(_ = try await subject.waitUntil(options: options, input: "input")) { error in
            guard let waiterFailureError = error as? WaiterFailureError<String> else {
                XCTFail("Error is not of expected type"); return
            }
            let expectedError = WaiterFailureError<String>(attempts: 3, failedOnMatch: true, result: .success("3"))
            XCTAssertEqual(waiterFailureError, expectedError)
        }
    }

    func test_waitUntil_throwsWhenUnmatchedErrorIsThrownByOperation() async throws {
        let config = try config()
        let mockThatThrows = Mock()
        mockThatThrows.throwsOnOperation = true
        let subject = Waiter(config: config, operation: mockThatThrows.operation(input:))
        let options = WaiterOptions(maxWaitTime: 120.0)
        await XCTAssertThrowsErrorAsync(_ = try await subject.waitUntil(options: options, input: "input")) { error in
            guard let waiterFailureError = error as? WaiterFailureError<String> else {
                XCTFail("Error is not of expected type"); return
            }
            let expectedError = WaiterFailureError<String>(attempts: 1, failedOnMatch: false, result: .failure(ClientError.unknownError("1")))
            XCTAssertEqual(waiterFailureError, expectedError)
        }
    }
}

// MARK: - Helper functions

/// Returns a `WaiterConfig` with acceptors suitable for use in the test being performed.
private func config(
    succeedOn succeedResult: Result<String, Error>? = nil,
    retryOn retryResult: Result<String, Error>? = nil,
    failOn failureResult: Result<String, Error>? = nil
) throws -> WaiterConfiguration<String, String> {
    var acceptors = [Acceptor]()

    // Add acceptors for the specified conditions
    if let succeedResult = succeedResult {
        acceptors.append(Acceptor(state: .success, matcher: { $1 == succeedResult }))
    }
    if let retryResult = retryResult {
        acceptors.append(Acceptor(state: .retry, matcher: { $1 == retryResult }))
    }
    if let failureResult = failureResult {
        acceptors.append(Acceptor(state: .failure, matcher: { $1 == failureResult }))
    }

    // This acceptor satisfies the "one success" requirement even though it never matches
    acceptors.append(Acceptor(state: .success, matcher: { _, _ in return false }))

    return try WaiterConfiguration(minDelay: 2.0, maxDelay: 10.0, acceptors: acceptors)
}

