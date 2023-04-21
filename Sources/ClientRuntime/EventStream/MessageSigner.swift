//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Protocol for signing messages.
public protocol MessageSigner {
    /// Signs a message.
    /// - Parameter message: The message to sign.
    /// - Returns: The signed message.
    mutating func sign(message: EventStream.Message) async throws -> EventStream.Message

    /// Signs an empty message.
    func signEmpty() async throws -> EventStream.Message
}
