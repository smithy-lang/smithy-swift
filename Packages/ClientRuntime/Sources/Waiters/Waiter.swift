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
        let retryer = WaiterRetryer<Input, Output>()
        let retryerContainer = WaiterRetryerContainer(retryer)
        return try await waitUntil(options: options, input: input, retryerContainer: retryerContainer)
    }

    func waitUntil(
        options: WaiterOptions,
        input: Input,
        retryerContainer: WaiterRetryerContainer<Input, Output>
    ) async throws -> WaiterOutcome<Output> {
        let minDelay = options.minDelay ?? config.minDelay
        let maxDelay = options.maxDelay ?? config.maxDelay
        let maxWaitTime = options.maxWaitTime
        let scheduler = WaiterScheduler(minDelay: minDelay, maxDelay: maxDelay, maxWaitTime: maxWaitTime)

        while !scheduler.isExpired {
            if let result = try await retryerContainer.waitThenRequest(scheduler: scheduler, input: input, config: config, operation: operation) {
                return result
            }
        }
        // Waiting has expired, throw an error back to the caller
        throw WaiterTimeoutError(attempts: scheduler.attempt)
    }
}
