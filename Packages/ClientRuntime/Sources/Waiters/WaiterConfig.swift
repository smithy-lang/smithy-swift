//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `WaiterConfig` contains the parameters for a predefined waiter.  `WaiterConfig` will
/// usually be code-generated from a Smithy definition for a Smithy waiter defined on an operation.
public struct WaiterConfig<Input, Output> {

    /// The minimum delay before a retry may be sent.  Defaults to `2.0` if not supplied.
    public let minDelay: TimeInterval
    /// The maximum delay before a retry may be sent.  Defaults to `120.0` if not supplied.
    public let maxDelay: TimeInterval
    /// The acceptors for this waiter.  Acceptors are evaluated in the order they are supplied.
    /// At least one `Acceptor` with the `success` state must be supplied.
    public let acceptors: [Acceptor]

    /// Creates a new `WaiterConfig` with the supplied parameters.
    public init(minDelay: TimeInterval?, maxDelay: TimeInterval?, acceptors: [Acceptor]) throws {
        guard acceptors.filter({ $0.state == .success }).count >= 1 else {
            throw WaiterConfigError(localizedDescription: "There must be at least one Acceptor with a success state")
        }
        self.minDelay = minDelay ?? 2.0
        self.maxDelay = maxDelay ?? 120.0
        self.acceptors = acceptors
    }
}
