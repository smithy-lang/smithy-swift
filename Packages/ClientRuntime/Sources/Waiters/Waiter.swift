//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// An object used to wait on an operation.
/// Intended to be a generic type for use when waiting on any Smithy `operation`.
/// May be reused for multiple waits, including concurrent operations.
public class Waiter<Input, Output> {

    /// The configuration this waiter was created with.
    public let config: WaiterConfiguration<Input, Output>

    /// The operation that this waiter will call one or more times while waiting on the success condition.
    public let operation: (Input) async throws -> Output

    /// Allows for advancing of time during waiter unit tests.
    /// The default hook does nothing.
    var postSchedulerUpdateHook: (WaiterScheduler) -> Void = { _ in }

    /// Creates a `waiter` object with the supplied config and operation.
    /// - Parameters:
    ///   - config: An instance of `WaiterConfiguration` that defines the default behavior of this waiter.
    ///   - operation: A closure that is called one or more times to perform the waiting operation;
    ///   takes an `Input` as its sole param & returns an `Output` asynchronously.
    ///   The `operation` closure throws an error if the operation cannot be performed or the
    ///   operation completes with an error.
    public init(
        config: WaiterConfiguration<Input, Output>,
        operation: @escaping (Input) async throws -> Output
    ) {
        self.config = config
        self.operation = operation
    }

    /// Initiates waiting, retrying the operation if necessary until the wait succeeds, fails, or times out.
    /// Returns a `WaiterOutcome` asynchronously on waiter success, throws an error asynchronously on
    /// waiter failure or timeout.
    /// - Parameters:
    ///   - options: `WaiterOptions` to be used to configure this wait.
    ///   - input: The `Input` object to be used as a parameter when performing the operation.
    /// - Returns: A `WaiterOutcome` with the result of the final, successful performance of the operation.
    /// - Throws: `WaiterFailureError` if the waiter fails due to matching an `Acceptor` with state `failure`
    /// or there is an error not handled by any `Acceptor.`
    ///
    /// `WaiterTimeoutError` if the waiter times out.
    @discardableResult
    public func waitUntil(
        options: WaiterOptions,
        input: Input
    ) async throws -> WaiterOutcome<Output> {
        let minDelay = options.minDelay ?? config.minDelay
        let maxDelay = options.maxDelay ?? config.maxDelay
        let maximumWaitTime = options.maximumWaitTime
        let scheduler = WaiterScheduler(minDelay: minDelay, maxDelay: maxDelay, maximumWaitTime: maximumWaitTime)

        while !scheduler.isExpired {
            // Find the required delay from the scheduler, and wait if required.
            if scheduler.currentDelay > 0.0 {
                try await Task.sleep(nanoseconds: UInt64(scheduler.currentDelay * 1_000_000_000.0))
            }

            // Try the operation, collect the result & update the scheduler (for test use only) for this attempt.
            let result = await Result<Output, Error>(catching: { try await operation(input) })
            scheduler.updateAfterRetry()
            postSchedulerUpdateHook(scheduler)

            // Test the acceptors, to see if one matches.  Take the first match if there is one.
            // If a match is found, take action as required.
            if let match = config.acceptors.compactMap({ $0.evaluate(input: input, result: result) }).first {
                switch match {
                case .success(let lastResult):
                    return WaiterOutcome(attempts: scheduler.attempt, result: lastResult)
                case .failure(let lastResult):
                    throw WaiterFailureError(attempts: scheduler.attempt, failedOnMatch: true, result: lastResult)
                case .retry:
                    break
                }
            // If no matching acceptor is found, fail if the result was an error.
            } else if case .failure(let error) = result {
                throw WaiterFailureError<Output>(
                    attempts: scheduler.attempt,
                    failedOnMatch: false,
                    result: .failure(error)
                )
            }
            // Loop back to the top for a retry.
        }
        // Waiting has expired, throw an error back to the caller
        throw WaiterTimeoutError(attempts: scheduler.attempt)
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
