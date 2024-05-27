//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Serializes modeled operation input into request messages.
///
/// Implementations do not necessarily have to perform complete serialization, but
/// may serialize parts of the input. This allows for serializers to be composed
/// together (which should be done by `Orchestrator`).
public protocol RequestMessageSerializer<InputType, RequestType> {

    /// The type of the modeled operation input.
    associatedtype InputType

    /// The type of the serialized request message.
    associatedtype RequestType: RequestMessage

    /// Applies the serializer to the given input, modifying the builder.
    /// - Parameters:
    ///   - input: The modeled operation input to serialize.
    ///   - builder: The builder for the serialized message.
    ///   - attributes: The attributes available to the serializer.
    func apply(input: InputType, builder: RequestType.RequestBuilderType, attributes: Context) throws
}
