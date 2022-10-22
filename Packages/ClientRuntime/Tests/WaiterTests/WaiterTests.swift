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

class WaiterTests: XCTestCase {

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

    /// This closure is to be used as a `postSchedulerUpdateHook` on the subject waiter during testing.
    /// Sets the waiter's scheduler so that it is time for the next request to be made.
    let waitEliminator = { (scheduler: WaiterScheduler) in
        let nextRequestDate = scheduler.nextRequestDate
        scheduler.now = { nextRequestDate }
    }

    // MARK: - waitUntil()

    // MARK: success

    func test_waitUntil_returnsSuccessWhenSuccessConditionMet() async throws {
        let config = try config(succeedOn: .success("1"))
        let subject = Waiter(config: config, operation: Mock().operation(input:))
        subject.postSchedulerUpdateHook = waitEliminator
        let options = WaiterOptions(maximumWaitTime: 120.0)
        let result = try await subject.waitUntil(options: options, input: "input")
        XCTAssertEqual(result, .init(attempts: 1, result: .success("1")))
    }

    // MARK: retry

    func test_waitUntil_retriesOnSuccessByDefault() async throws {
        let config = try config(succeedOn: .success("4"))
        let subject = Waiter(config: config, operation: Mock().operation(input:))
        subject.postSchedulerUpdateHook = waitEliminator
        let options = WaiterOptions(maximumWaitTime: 120.0)
        let result = try await subject.waitUntil(options: options, input: "input")
        XCTAssertEqual(result, .init(attempts: 4, result: .success("4")))
    }

    func test_waitUntil_retriesUntilRetryConditionMet() async throws {
        let config = try config(succeedOn: .success("3"))
        let subject = Waiter(config: config, operation: Mock().operation(input:))
        subject.postSchedulerUpdateHook = waitEliminator
        let options = WaiterOptions(maximumWaitTime: 120.0)
        let result = try await subject.waitUntil(options: options, input: "input")
        XCTAssertEqual(result, .init(attempts: 3, result: .success("3")))
    }

    // MARK: - failure

    func test_waitUntil_throwsWhenFailureIsMatched() async throws {
        let config = try config(failOn: .success("3"))
        let subject = Waiter(config: config, operation: Mock().operation(input:))
        subject.postSchedulerUpdateHook = waitEliminator
        let options = WaiterOptions(maximumWaitTime: 120.0)
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
        subject.postSchedulerUpdateHook = waitEliminator
        let options = WaiterOptions(maximumWaitTime: 120.0)
        await XCTAssertThrowsErrorAsync(_ = try await subject.waitUntil(options: options, input: "input")) { error in
            guard let waiterFailureError = error as? WaiterFailureError<String> else {
                XCTFail("Error is not of expected type"); return
            }
            let expectedError = WaiterFailureError<String>(attempts: 1, failedOnMatch: false, result: .failure(ClientError.unknownError("1")))
            XCTAssertEqual(waiterFailureError, expectedError)
        }
    }

    // MARK: - timeout

    func test_waitUntil_retriesUntilTimeoutIfNoSuccessOrFailure() async throws {
        let config = try config()
        let subject = Waiter(config: config, operation: Mock().operation(input:))
        subject.postSchedulerUpdateHook = waitEliminator
        let options = WaiterOptions(maximumWaitTime: 120.0)
        await XCTAssertThrowsErrorAsync(_ = try await subject.waitUntil(options: options, input: "input")) { error in
            XCTAssert(error is WaiterTimeoutError)
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
}

/// An async version of `XCTAssertThrowsError`.
fileprivate func XCTAssertThrowsErrorAsync(
    _ exp: @autoclosure () async throws -> Void,
    _ block: (Error) -> Void
) async {
    do {
        try await exp()
        XCTFail("Should have thrown error")
    } catch {
        block(error)
    }
}
