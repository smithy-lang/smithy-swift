//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Smithy.Attributes
import struct SmithyEventStreamsAPI.Message

/// Protocol for signing messages.
public protocol MessageDataSigner: Sendable {

    /// Signs a message.
    /// - Parameters:
    ///   - payload: The message to be signed.
    ///   - previousSignature: The signature from the previously signed message.
    ///   - signingProperties: The properties to be used for message signing.
    /// - Returns: A `SigningResult` with the message and its signature.
    func signEvent(
        payload: Data,
        previousSignature: String,
        signingProperties: Attributes
    ) async throws -> SigningResult<Message>
}

public struct SigningResult<T: Sendable>: Sendable {
    public let output: T
    public let signature: String

    public init(output: T, signature: String) {
        self.output = output
        self.signature = signature
    }
}
