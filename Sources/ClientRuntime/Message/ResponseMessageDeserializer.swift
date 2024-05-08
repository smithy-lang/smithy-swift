//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Deserializes service response messages into modeled operation output or error.
public protocol ResponseMessageDeserializer<OutputType, ResponseType, AttributesType> {
    /// The type of the modeled operation output.
    associatedtype OutputType

    /// The type of the serialized response message.
    associatedtype ResponseType: ResponseMessage

    /// The type of the attributes the deserializer requires.
    associatedtype AttributesType: HasAttributes

    /// Applies the deserializer to the given response, returning the modeled operation output.
    /// - Parameters:
    ///   - response: The response message.
    ///   - attributes: The attributes available to the deserializer.
    /// - Returns: The deserialized modeled response or modeled error. Throws if deserialization fails.
    func deserialize(response: ResponseType, attributes: AttributesType) async throws -> Result<OutputType, Error>
}
