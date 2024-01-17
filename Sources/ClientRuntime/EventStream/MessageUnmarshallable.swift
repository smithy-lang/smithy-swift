//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Unmarshals a `Message` into a event stream event.
/// Codgegen generates a conformance to this protocol for each event stream event output.
public protocol MessageUnmarshallable {
    /// Unmarshals a `Message` into a event stream event.
    /// - Parameters:
    ///   - message: The message to unmarshal.
    ///   - decoder: ResponseDecoder to use to decode the event stream event.
    ///              Note: event type may contain nested types that need to be decoded
    ///              using the same decoder.
    init(message: EventStream.Message, decoder: ResponseDecoder) throws
}

public typealias UnmarshalClosure<T> = (EventStream.Message) throws -> T

/// Provides an `UnmarshalClosure` for event payloads that are Swift `Decodable`.
/// - Parameter responseDecoder: The Swift `Decoder` to be used for decoding this event payload.
/// - Returns: An `UnmarshalClosure` that uses the provided decoder to decode event payloads.
public func jsonUnmarshalClosure<T: MessageUnmarshallable>(responseDecoder: ResponseDecoder) -> UnmarshalClosure<T> {
    return { message in
        try T(message: message, decoder: responseDecoder)
    }
}
