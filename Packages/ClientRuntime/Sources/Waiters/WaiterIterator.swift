//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `WaiterIterator` performs the waited operation using the timing in the retry strategy.
/// A new iterator is created for every wait operation.
/// Once the wait operation concludes with either success or failure, the `WaiterIterator`
/// ends iteration.
public class WaiterIterator<Input, Output>: AsyncIteratorProtocol {
    let input: Input
    let acceptors: [Acceptor<Input, Output>]
    let scheduler: WaiterScheduler
    let operation: (Input) async throws -> Output

    private var finished = false

    init(input: Input, acceptors: [Acceptor<Input, Output>], minDelay: TimeInterval, maxDelay: TimeInterval, maximumWaitTime: TimeInterval, operation: @escaping (Input) async throws -> Output) {
        self.input = input
        self.acceptors = acceptors
        self.operation = operation
        self.scheduler = WaiterScheduler(minDelay: minDelay, maxDelay: maxDelay, maximumWaitTime: maximumWaitTime)
    }

    // MARK: - AsyncIteratorProtocol

    public func next() async throws -> WaiterStatus<Output>? {
        // When success is reached, the finished flag is set.
        // Returning nil from this function causes the async iterator
        // to end.
        // The iterator ends automatically after an error is thrown, so
        // no need to set finished (thereby nil-terminating the
        // AsyncSequence) after a failure event.
        guard !finished else { return nil }

        // Find the required delay from the scheduler, and wait if required.
        let delay = scheduler.currentDelay
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000.0))

        // Try the operation, and collect either output or an error.
        var output: Output?
        var error: Error?
        do {
            output = try await operation(input)
        } catch let e {
            error = e
        }

        // Test the acceptors, in order, to see if one matches.
        // Once a match is found, take action as required by that acceptor's state.
        for acceptor in acceptors {
            if acceptor.matcher.isAMatch(input: input, output: output, error: error) {
                switch acceptor.state {
                case .success:
                    finished = true
                    guard let output = output else {
                        throw ClientError.unknownError("`success` Acceptor succeeded with nil output")
                    }
                    return .success(output)
                case .retry:
                    return .retry(scheduler.updateAfterRetry())
                case .failure:
                    throw error ?? ClientError.unknownError("Failure condition encountered while waiting")
                }
            }
        }

        // If no acceptor matched the response and an error was thrown, fail with the error.
        // Otherwise, initiate a retry.
        if let error = error {
            throw error
        } else {
            return .retry(scheduler.updateAfterRetry())
        }
    }
}
