//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyEventStreamsAPI

/// Protocol for signing messages.
public protocol MessageSigner {
    /// Signs a message.
    /// - Parameter message: The message to sign.
    /// - Returns: The signed message.
    mutating func sign(message: Message) async throws -> Message

    /// Signs an empty message.
    func signEmpty() async throws -> Message
}
