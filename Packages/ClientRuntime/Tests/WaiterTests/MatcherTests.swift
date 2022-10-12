//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime

class MatcherTests: XCTestCase {
    typealias Matcher = Acceptor<String, String>.Matcher

    // MARK: - output matcher

    func test_output_isAMatch_returnsFalseWhenOutputIsNil() throws {
        let subject = Matcher.output { _ in return true }
        XCTAssertFalse(subject.isAMatch(input: "input", output: nil, error: nil))
    }

    func test_output_isAMatch_returnsTestClosureResultWhenOutputIsNonNil() throws {
        let subject = Matcher.output { $0 == "match" }
        XCTAssertFalse(subject.isAMatch(input: "input", output: "no match", error: nil))
        XCTAssertTrue(subject.isAMatch(input: "input", output: "match", error: nil))
    }

    // MARK: - input/output matcher

    func test_inputOutput_isAMatch_returnsFalseWhenOutputIsNil() throws {
        let subject = Matcher.inputOutput { _, _ in return true }
        XCTAssertFalse(subject.isAMatch(input: "input", output: nil, error: nil))
    }

    func test_inputOutput_isAMatch_returnsTestClosureResultWhenOutputIsNonNil() throws {
        let subject = Matcher.inputOutput { i, o in return i == "match" && o == "match" }
        XCTAssertFalse(subject.isAMatch(input: "match", output: "no match", error: nil))
        XCTAssertTrue(subject.isAMatch(input: "match", output: "match", error: nil))
    }

    // MARK: - success matcher

    func test_success_isAMatch_returnsTrueWhenSuccessIsTrueAndOutputIsNonNil() throws {
        let subject = Matcher.success(true)
        XCTAssertTrue(subject.isAMatch(input: "input", output: "output", error: nil))
    }

    func test_success_isAMatch_returnsFalseWhenSuccessIsTrueAndOutputIsNil() throws {
        let subject = Matcher.success(true)
        XCTAssertFalse(subject.isAMatch(input: "input", output: nil, error: nil))
    }

    func test_success_isAMatch_returnsFalseWhenSuccessIsFalseAndOutputIsNonNil() throws {
        let subject = Matcher.success(false)
        XCTAssertFalse(subject.isAMatch(input: "input", output: "output", error: nil))
    }

    func test_success_isAMatch_returnsTrueWhenSuccessIsFalseAndOutputIsNil() throws {
        let subject = Matcher.success(false)
        XCTAssertTrue(subject.isAMatch(input: "input", output: nil, error: nil))
    }

    // MARK: - error type matcher

    struct ErrorA: Error {
        var localDescription: String? { "error A" }
    }
    struct ErrorB: Error {
        var localDescription: String? { "error B" }
    }

    func test_errorType_returnsFalseWhenErrorIsNil() async throws {
        let subject = Matcher.errorType(ErrorA.self)
        XCTAssertFalse(subject.isAMatch(input: "input", output: "output", error: nil))
    }

    func test_errorType_returnsTrueWhenErrorIsOfTheCorrectType() async throws {
        let subject = Matcher.errorType(ErrorA.self)
        XCTAssertTrue(subject.isAMatch(input: "input", output: "output", error: ErrorA()))
    }

    func test_errorType_returnsFalseWhenErrorIsOfADifferentType() async throws {
        let subject = Matcher.errorType(ErrorA.self)
        XCTAssertFalse(subject.isAMatch(input: "input", output: "output", error: ErrorB()))
    }
}
