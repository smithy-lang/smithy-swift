//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime

class WaiterIteratorTests: XCTestCase {

    enum MockOperation {
        static func succeeded(input: String) async throws -> String { "succeeded" }
        static func notYet(input: String) async throws -> String { "notYet" }
        static func failed(input: String) async throws -> String { "failed" }
        static func throwsError(input: String) async throws -> String { throw ClientError.unknownError("testError") }
    }

    // MARK: - next()

    // MARK: .success status

    func test_next_returnsSuccessWhenSuccessConditionMet() async throws {
        let acceptors = [Acceptor<String, String>(state: .success, matcher: .output({ $0 == "succeeded" }))]
        let subject = newIterator(acceptors: acceptors, operation: MockOperation.succeeded(input:))
        let result = try await subject.next()
        switch result {
        case .success(let output):
            XCTAssertEqual(output, "succeeded")
        default:
            XCTFail("Should have returned success")
        }
    }

    func test_next_endsSequenceAfterSuccess() async throws {
        let acceptors = [Acceptor<String, String>(state: .success, matcher: .output({ $0 == "succeeded" }))]
        let subject = newIterator(acceptors: acceptors, operation: MockOperation.succeeded(input:))
        _ = try await subject.next()
        let result = try await subject.next()
        XCTAssertNil(result)
    }

    // MARK: .retry status

    func test_next_returnsRetryWhenRetryConditionMet() async throws {
        let acceptors = [Acceptor<String, String>(state: .retry, matcher: .output({ $0 == "notYet" }))]
        let subject = newIterator(acceptors: acceptors, operation: MockOperation.notYet(input:))
        let result = try await subject.next()
        switch result {
        case .retry:
            break // test passes, retry was expected
        default:
            XCTFail("Should have returned retry")
        }
    }

    func test_next_continuesSequenceAfterRetry() async throws {
        let acceptors = [Acceptor<String, String>(state: .retry, matcher: .output({ $0 == "notYet" }))]
        let subject = newIterator(acceptors: acceptors, operation: MockOperation.notYet(input:))
        _ = try await subject.next()
        let result = try await subject.next()
        XCTAssertNotNil(result)
    }

    func test_next_failsWithErrorOnTimeout() async throws {
        let acceptors = [Acceptor<String, String>(state: .retry, matcher: .output({ $0 == "notYet" }))]
        let subject = newIterator(acceptors: acceptors, maximumWaitTime: 0.0, operation: MockOperation.notYet(input:))
        _ = try await subject.next()
        do {
            _ = try await subject.next()
            XCTFail("Error was expected")
        } catch {
            // test passes, error was expected
        }
    }

    // MARK: .failure status

    func test_next_throwsWhenFailureConditionMet() async throws {
        let acceptors = [Acceptor<String, String>(state: .failure, matcher: .output({ $0 == "failed" }))]
        let subject = newIterator(acceptors: acceptors, operation: MockOperation.failed(input:))
        do {
            _ = try await subject.next()
            XCTFail("Call to next() should have thrown")
        } catch {
            // Test passes, error was expected
        }
    }

    func test_next_throwsOnUnhandledError() async throws {
        let acceptors = [Acceptor<String, String>(state: .failure, matcher: .output({ $0 == "failed" }))]
        let subject = newIterator(acceptors: acceptors, operation: MockOperation.throwsError(input:))
        do {
            _ = try await subject.next()
            XCTFail("Call to next() should have thrown")
        } catch {
            // Test passes, error was expected
        }
    }

    // MARK: - Helper functions

    private func newIterator(acceptors: [Acceptor<String, String>], maximumWaitTime: TimeInterval = 360.0,
                             operation:  @escaping (String) async throws -> String) -> WaiterIterator<String, String> {
        // Set extremely small delays here to minimize the time to complete tests.
        // Can't set zero because it causes divide-by-zero in the Smithy retry logic.
        return WaiterIterator<String, String>(input: "input", acceptors: acceptors, minDelay: 0.00001,
                                              maxDelay: 0.00001, maximumWaitTime: maximumWaitTime, operation: operation)
    }
}
