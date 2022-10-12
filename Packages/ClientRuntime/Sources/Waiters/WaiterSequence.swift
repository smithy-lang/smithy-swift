//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Enables a wait operation to be expressed as a sequence of asynchronous events.
public struct WaiterSequence<Input, Output>: AsyncSequence {
    public typealias AsyncIterator = WaiterIterator<Input, Output>
    public typealias Element = WaiterStatus<Output>

    public let waiter: Waiter<Input, Output>

    // MARK: - AsyncSequence protocol

    public func makeAsyncIterator() -> WaiterIterator<Input, Output> {
        WaiterIterator(input: waiter.input, acceptors: waiter.acceptors, minDelay: waiter.minDelay, maxDelay: waiter.maxDelay, maximumWaitTime: waiter.maximumWaitTime, operation: waiter.operation)
    }
}
