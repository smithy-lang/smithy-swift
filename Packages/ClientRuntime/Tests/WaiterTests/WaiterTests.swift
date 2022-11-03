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

    fileprivate class WaiterRetryerMock {
        typealias Input = String
        typealias Output = String

        let returnVals: [WaiterOutcome<String>?]
        var callCounter = 0
        var scheduler: WaiterScheduler!
        var errorToThrow: Error?

        init(returnVals: [WaiterOutcome<String>?]) {
            self.returnVals = returnVals
        }

        func waitThenRequest(
            scheduler: WaiterScheduler,
            input: Input, config: ClientRuntime.WaiterConfiguration<String, String>,
            operation: (Input) async throws -> Output
        ) async throws -> ClientRuntime.WaiterOutcome<String>? {
            defer {
                scheduler.updateAfterRetry()
                callCounter += 1
            }

            // Save the scheduler so it can be tested for proper config
            self.scheduler = scheduler

            // Advance the scheduler clock to the time for the next request,
            // so tests proceed with no delay
            let now = scheduler.now()
            let offset = scheduler.currentDelay
            scheduler.now = { now + offset }

            // Return or throw as needed
            if let errorToThrow = errorToThrow {
                throw errorToThrow
            } else if callCounter < returnVals.count {
                return returnVals[callCounter]
            } else {
                return nil
            }
        }
    }

    // MARK: - waitUntil()

    // MARK: - scheduler config

    func test_scheduler_isConfiguredFromTheWaiterConfig() async throws {
        let minDelay = TimeInterval.random(in: 2.0...10.0)
        let maxDelay = TimeInterval.random(in: 20.0...30.0)
        let maxWaitTime = TimeInterval.random(in: 60.0...120.0)
        let mock = WaiterRetryerMock(returnVals: [WaiterOutcome.init(attempts: 1, result: .success("output"))])
        let retryer = WaiterRetryer(closure: mock.waitThenRequest(scheduler:input:config:operation:))
        let config = config(minDelay: minDelay, maxDelay: maxDelay)
        let options = WaiterOptions(maxWaitTime: maxWaitTime)
        let subject = Waiter(config: config, operation: {_ in return "output" }, retryer: retryer)
        _ = try await subject.waitUntil(options: options, input: "input")
        XCTAssertEqual(mock.scheduler.minDelay, minDelay)
        XCTAssertEqual(mock.scheduler.maxDelay, maxDelay)
        XCTAssertEqual(mock.scheduler.maxWaitTime, maxWaitTime)
    }

    func test_scheduler_isConfiguredWithOverridesFromOptionsWhenProvided() async throws {
        let minDelay = TimeInterval.random(in: 2.0...10.0)
        let maxDelay = TimeInterval.random(in: 20.0...30.0)
        let maxWaitTime = TimeInterval.random(in: 60.0...120.0)
        let mock = WaiterRetryerMock(returnVals: [WaiterOutcome.init(attempts: 1, result: .success("output"))])
        let retryer = WaiterRetryer(closure: mock.waitThenRequest(scheduler:input:config:operation:))
        let config = config(minDelay: minDelay, maxDelay: maxDelay)
        let optionsMinDelay = TimeInterval.random(in: 2.0...10.0)
        let optionsMaxDelay = TimeInterval.random(in: 20.0...30.0)
        let options = WaiterOptions(minDelay: optionsMinDelay, maxDelay: optionsMaxDelay, maxWaitTime: maxWaitTime)
        let subject = Waiter(config: config, operation: {_ in return "output" }, retryer: retryer)
        _ = try await subject.waitUntil(options: options, input: "input")
        XCTAssertEqual(mock.scheduler.minDelay, optionsMinDelay)
        XCTAssertEqual(mock.scheduler.maxDelay, optionsMaxDelay)
        XCTAssertEqual(mock.scheduler.maxWaitTime, maxWaitTime)
    }

    // MARK: success

    func test_waitUntil_returnsSuccessWhenRetryerSignalsSuccess() async throws {
        let success = WaiterOutcome(attempts: 1, result: .success("output"))
        let mock = WaiterRetryerMock(returnVals: [success])
        let retryer = WaiterRetryer(closure: mock.waitThenRequest(scheduler:input:config:operation:))
        let subject = Waiter<String, String>(config: config(), operation: { _ in return "output" }, retryer: retryer)
        let result = try await subject.waitUntil(options: options, input: "input")
        XCTAssertEqual(result, success)
    }

    // MARK: retry

    func test_waitUntil_retriesWhenRetryerSignalsRetry() async throws {
        let outcomes: [WaiterOutcome<String>?] = [
            nil,
            nil,
            WaiterOutcome(attempts: 3, result: .success("output"))
        ]
        let mock = WaiterRetryerMock(returnVals: outcomes)
        let retryer = WaiterRetryer(closure: mock.waitThenRequest(scheduler:input:config:operation:))
        let subject = Waiter<String, String>(config: config(), operation: { _ in return "output" }, retryer: retryer)
        let result = try await subject.waitUntil(options: options, input: "input")
        XCTAssertEqual(result, outcomes.last!)
    }

    // MARK: - failure

    func test_waitUntil_failsWhenRetryerReturnsAnError() async throws {
        let mock = WaiterRetryerMock(returnVals: [nil])
        mock.errorToThrow = ClientError.unknownError(UUID().uuidString)
        let retryer = WaiterRetryer(closure: mock.waitThenRequest(scheduler:input:config:operation:))
        let subject = Waiter<String, String>(config: config(), operation: { _ in return "output" }, retryer: retryer)
        await XCTAssertThrowsErrorAsync(_ = try await subject.waitUntil(options: options, input: "input")) {
            XCTAssertEqual($0.localizedDescription, mock.errorToThrow?.localizedDescription)
        }
    }
    // MARK: - timeout

    func test_waitUntil_throwsATimeoutErrorOnTimeout() async throws {
        let mock = WaiterRetryerMock(returnVals: [nil])
        let retryer = WaiterRetryer(closure: mock.waitThenRequest(scheduler:input:config:operation:))
        let subject = Waiter<String, String>(config: config(), operation: { _ in return "output" }, retryer: retryer)
        let closure: () async throws -> Void = {
            while true {
                _ = try await subject.waitUntil(options: self.options, input: "input")
            }
        }
        await XCTAssertThrowsErrorAsync(try await closure()) {
            XCTAssert($0 is WaiterTimeoutError)
        }
    }

    // MARK: - Helpers

    func config(minDelay: TimeInterval = 1.0, maxDelay: TimeInterval = 4.0) -> WaiterConfiguration<String, String> {
        let acceptor = Acceptor(state: .success, matcher: { _, _ in return true })
        return try! WaiterConfiguration<String, String>(acceptors: [acceptor], minDelay: minDelay, maxDelay: maxDelay)
    }

    let options = WaiterOptions(maxWaitTime: 8.0)
}
