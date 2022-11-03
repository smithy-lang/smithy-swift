//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A type which tries the waited operation after a delay, then returns or throws the result.
/// Called by the `Waiter` to make the initial request, then called again for an additional request when retry
/// is needed.
/// A custom closure may be injected at initialization to allow `WaiterRetryer` to be used as a mock.
class WaiterRetryer<Input, Output> {
    typealias WaitThenRequest =
        (WaiterScheduler, Input, WaiterConfiguration<Input, Output>, (Input) async throws -> Output)
            async throws -> WaiterOutcome<Output>?

    private let closure: WaitThenRequest

    init(closure: @escaping WaitThenRequest = WaiterRetryer.waitThenRequest) {
        self.closure = closure
    }

    func waitThenRequest(
        scheduler: WaiterScheduler,
        input: Input,
        config: WaiterConfiguration<Input, Output>,
        operation: (Input) async throws -> Output
    ) async throws -> WaiterOutcome<Output>? {
        try await closure(scheduler, input, config, operation)
    }

    // MARK: - Private methods

    private static func waitThenRequest(
        scheduler: WaiterScheduler,
        input: Input,
        config: WaiterConfiguration<Input, Output>,
        operation: (Input) async throws -> Output
    ) async throws -> WaiterOutcome<Output>? {
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
                return WaiterOutcome(attempts: scheduler.attempts, result: lastResult)
            case .failure(let lastResult):
                throw WaiterFailureError<Output>(attempts: scheduler.attempts, failedOnMatch: true, result: lastResult)
            case .retry:
                return nil  // Returning nil causes retry, if time remains
            }
        // If no matching acceptor is found, fail if the result was an error.
        } else if case .failure(let error) = result {
            throw WaiterFailureError<Output>(
                attempts: scheduler.attempts,
                failedOnMatch: false,
                result: .failure(error)
            )
        }
        // Since no acceptor matched and the response was not an unhandled error,
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
