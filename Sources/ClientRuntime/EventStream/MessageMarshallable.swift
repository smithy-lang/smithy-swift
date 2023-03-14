//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Marshals an event stream event into a `Message`.
/// Codgegen generates a conformance to this protocol for each event stream event input.
public protocol MessageMarshallable {
    /// Marshals a event stream event into a `Message`.
    /// - Parameters:
    ///   - encoder: RequestEncoder to use to encode the event stream event.
    ///              Note: event type may contain nested types that need to be encoded
    ///              using the same encoder.
    /// - Returns: The marshalled `Message`.
    func marshall(encoder: RequestEncoder) throws -> EventStream.Message
}
