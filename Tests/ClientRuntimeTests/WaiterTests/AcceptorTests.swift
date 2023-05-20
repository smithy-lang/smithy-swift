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

class AcceptorTests: XCTestCase {
    let input = "input"
    let output = "output"
    let error = UnknownClientError("XCTestError")

    // MARK: - .success state

    func test_evaluate_success_returnsSuccessWithOutputOnMatch() throws {
        let subject = Acceptor(state: .success, matcher: { _, _ in return true })
        let match = subject.evaluate(input: input, result: .success(output))
        XCTAssertEqual(match, .success(.success(output)))
    }

    func test_evaluate_success_returnsSuccessWithErrorOnMatch() throws {
        let subject = Acceptor(state: .success, matcher: { _, _ in return true })
        let match = subject.evaluate(input: input, result: .failure(error))
        XCTAssertEqual(match, .success(.failure(error)))
    }

    func test_evaluate_success_returnsNilOnNoMatch() throws {
        let subject = Acceptor(state: .success, matcher: { _, _ in return false })
        let match = subject.evaluate(input: input, result: .success(output))
        XCTAssertNil(match)
    }

    // MARK: - .retry state

    func test_evaluate_retry_returnsRetryOnOutputMatch() throws {
        let subject = Acceptor(state: .retry, matcher: { _, _ in return true })
        let match = subject.evaluate(input: input, result: .success(output))
        XCTAssertEqual(match, .retry)
    }

    func test_evaluate_retry_returnsRetryOnErrorMatch() throws {
        let subject = Acceptor(state: .retry, matcher: { _, _ in return true })
        let match = subject.evaluate(input: input, result: .failure(error))
        XCTAssertEqual(match, .retry)
    }

    func test_evaluate_retry_returnsNilOnNoMatch() throws {
        let subject = Acceptor(state: .retry, matcher: { _, _ in return false })
        let match = subject.evaluate(input: input, result: .success(output))
        XCTAssertNil(match)
    }

    // MARK: - .failure state

    func test_evaluate_failure_returnsFailureWithOutputOnMatch() throws {
        let subject = Acceptor(state: .failure, matcher: { _, _ in return true })
        let match = subject.evaluate(input: input, result: .success(output))
        XCTAssertEqual(match, .failure(.success(output)))
    }

    func test_evaluate_failure_returnsFailureWithErrorOnMatch() throws {
        let subject = Acceptor(state: .failure, matcher: { _, _ in return true })
        let match = subject.evaluate(input: input, result: .failure(error))
        XCTAssertEqual(match, .failure(.failure(error)))
    }

    func test_evaluate_failure_returnsNilOnNoMatch() throws {
        let subject = Acceptor(state: .failure, matcher: { _, _ in return false })
        let match = subject.evaluate(input: input, result: .success(output))
        XCTAssertNil(match)
    }
}
