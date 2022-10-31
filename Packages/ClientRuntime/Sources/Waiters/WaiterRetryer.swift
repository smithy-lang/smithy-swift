//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


/// The interface for the type which delays per the wait schedule, performs the request, and evaluates the result.
/// Called by the `Waiter` to make the initial request, then called again for an additional request when retry is needed.
/// The protocol allows `WaiterRetryer` to be mocked for testing.
protocol WaiterRetryerInterface {
    associatedtype RetryerInput
    associatedtype RetryerOutput

    func waitThenRequest(
        scheduler: WaiterScheduler,
        input: RetryerInput,
        config: WaiterConfiguration<RetryerInput, RetryerOutput>,
        operation: (RetryerInput) async throws -> RetryerOutput
    ) async throws -> WaiterOutcome<RetryerOutput>?
}

/// Container used to type-erase the retryer which implements `WaiterRetryerInterface`
/// Used to permit injection of a `WaiterRetryerMock` when testing `Waiter`.
class WaiterRetryerContainer<Input, Output>: WaiterRetryerInterface {
    typealias RetryerInput = Input
    typealias RetryerOutput = Output

    let closure: (WaiterScheduler, RetryerInput, WaiterConfiguration<RetryerInput, RetryerOutput>, (RetryerInput) async throws -> RetryerOutput) async throws -> WaiterOutcome<RetryerOutput>?

    init<T: WaiterRetryerInterface>(_ inner: T) where T.RetryerInput == RetryerInput, T.RetryerOutput == RetryerOutput {
        self.closure = inner.waitThenRequest(scheduler:input:config:operation:)
    }

    func waitThenRequest(scheduler: WaiterScheduler, input: Input, config: WaiterConfiguration<Input, Output>, operation: (Input) async throws -> Output) async throws -> WaiterOutcome<Output>? {
        try await closure(scheduler, input, config, operation)
    }
}

class WaiterRetryer<Input, Output>: WaiterRetryerInterface {
    typealias RetryerInput = Input
    typealias RetryerOutput = Output

    func waitThenRequest(scheduler: WaiterScheduler, input: Input, config: WaiterConfiguration<Input, Output>, operation: (Input) async throws -> Output) async throws -> WaiterOutcome<Output>? {
        // Find the required delay from the scheduler, and wait if required.
        if scheduler.currentDelay > 0.0 {
            try await Task.sleep(nanoseconds: UInt64(scheduler.currentDelay * 1_000_000_000.0))
        }

        // Try the operation, collect the result & update the scheduler (for test use only) for this attempt.
        let result = await Result<Output, Error>(catching: { try await operation(input) })
        scheduler.updateAfterRetry()

        // Test the acceptors, to see if one matches.  Take the first match if there is one.
        // If a match is found, take action as required.
        if let match = config.acceptors.compactMap({ $0.evaluate(input: input, result: result) }).first {
            switch match {
            case .success(let lastResult):
                return WaiterOutcome(attempts: scheduler.attempt, result: lastResult)
            case .failure(let lastResult):
                throw WaiterFailureError<Output>(attempts: scheduler.attempt, failedOnMatch: true, result: lastResult)
            case .retry:
                return nil  // Returning nil causes retry, if time remains
            }
        // If no matching acceptor is found, fail if the result was an error.
        } else if case .failure(let error) = result {
            throw WaiterFailureError<Output>(
                attempts: scheduler.attempt,
                failedOnMatch: false,
                result: .failure(error)
            )
        }
        // Since no acceptor match and the response was not an unhandled error,
        // return nil to cause retry, if time remains
        return nil
    }
}

// MARK: - Helper methods

fileprivate extension Result where Failure == Error {

    /// The `Swift.Result` type has a similar initializer, but it is not asynchronous.
    init(catching body: () async throws -> Success) async {
        do {
            self = .success(try await body())
        } catch {
            self = .failure(error)
        }
    }
}
