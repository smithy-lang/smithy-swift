//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Thrown when a `WaiterConfig` is constructed with invalid parameters.
struct WaiterConfigError: Error {
    var localizedDescription: String?
}

/// Thrown when a waiter matches a failure acceptor on an attempt to call the waited operation.
public struct WaiterFailureError<Output>: Error {
    /// The number of attempts at the operation that were made while waiting.
    public let attempts: Int

    /// `true` if the failure was due to an `Acceptor` with state `failure` being matched,
    /// `false` if the failure was due to an operation error not matched by any `Acceptor`.
    public let failedOnMatch: Bool

    /// The result of the final (and necessarily successful) operation performed while waiting.
    public let result: Result<Output, Error>
}

/// Thrown when a waiter timeouts.
public struct WaiterTimeoutError: Error {
    /// The number of attempts at the operation that were made while waiting.
    public let attempts: Int
}
