//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Makes a waiter operation, as configured by the caller, into an async sequence of waiter status events.
/// Intended to be a generic type for use when waiting on any Smithy `operation`.
public class Waiter<Input, Output> {
    public let input: Input
    public let acceptors: [Acceptor<Input, Output>]
    let minDelay: TimeInterval
    let maxDelay: TimeInterval
    let maximumWaitTime: TimeInterval
    public let operation: (Input) async throws -> Output

    public init(input: Input, acceptors: [Acceptor<Input, Output>], minDelay: TimeInterval, maxDelay: TimeInterval, maximumWaitTime: TimeInterval, operation: @escaping (Input) async throws -> Output) {
        self.input = input
        self.acceptors = acceptors
        self.minDelay = minDelay
        self.maxDelay = maxDelay
        self.maximumWaitTime = maximumWaitTime
        self.operation = operation
    }

    public func asyncSequence() -> WaiterSequence<Input, Output> {
        return WaiterSequence(waiter: self)
    }
}
