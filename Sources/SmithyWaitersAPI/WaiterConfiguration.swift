//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `WaiterConfiguration` contains the parameters for a predefined waiter on a given operation.
/// `WaiterConfiguration` will usually be code-generated from a Smithy definition for a Smithy
/// waiter defined on an operation.
public struct WaiterConfiguration<Input, Output> {

    /// The minimum delay before a retry may be sent.  Defaults to `2.0` if not supplied.
    public let minDelay: TimeInterval
    /// The maximum delay before a retry may be sent.  Defaults to `120.0` if not supplied.
    public let maxDelay: TimeInterval
    /// The acceptors for this waiter.  Acceptors are evaluated in the order they are supplied.
    /// At least one `Acceptor` with the `success` state must be supplied.
    public let acceptors: [Acceptor]

    /// Creates a new `WaiterConfiguration` with the supplied parameters.
    /// - Parameters:
    ///   - minDelay: The minimum delay before a retry may be sent.  Defaults to `2.0` if not supplied.
    ///   - maxDelay: The maximum delay before a retry may be sent.  Defaults to `120.0` if not supplied.
    ///   - acceptors: The acceptors for this waiter.  Acceptors are evaluated in the order they are supplied.
    /// At least one `Acceptor` with the `success` state must be supplied.
    /// - Throws: `WaiterConfigurationError` if the `acceptors` do not include at least one member with state `success`.
    public init(
        acceptors: [Acceptor],
        minDelay: TimeInterval = 2.0,
        maxDelay: TimeInterval = 120.0
    ) throws {
        guard acceptors.filter({ $0.state == .success }).count >= 1 else {
            let localizedDescription = "There must be at least one Acceptor with a success state"
            throw WaiterConfigurationError(localizedDescription: localizedDescription)
        }
        self.minDelay = minDelay
        self.maxDelay = maxDelay
        self.acceptors = acceptors
    }
}
