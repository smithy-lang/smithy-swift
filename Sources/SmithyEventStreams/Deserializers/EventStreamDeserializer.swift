//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import enum Smithy.ByteStream
import protocol Smithy.ResponseMessage
@_spi(SchemaBasedSerde)
import class Smithy.Schema
import protocol Smithy.SmithyDocument
@_spi(SchemaBasedSerde)
import class Smithy.StreamingTrait
import typealias SmithyEventStreamsAPI.UnmarshalClosure
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.DeserializableStruct
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ThrowByDefaultShapeDeserializer

/// A deserializer that may be used to deserialize an event stream from a response.
///
/// This deserializer should only be used on an output structure.  It will only deserialize the
/// event stream on the output, nothing else.  If the output structure has no event stream
/// member, it will throw an error.
/// It will throw a "not implemented" error if deserialization of any other type is attempted.
@_spi(SchemaBasedSerde)
public struct EventStreamDeserializer: ThrowByDefaultShapeDeserializer {
    let codec: any Codec
    let response: ResponseMessage

    public init(codec: any Codec, response: ResponseMessage) {
        self.codec = codec
        self.response = response
    }

    public func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws {

        // Locate the event stream member on this structure.
        guard let member = schema.members.first(where: { $0.type == .union && $0.hasTrait(StreamingTrait.self) }) else {
            throw SerializerError("Streaming response received but no event streaming member")
        }

        // Call the read consumer with the streaming member and this same deserializer.
        // The readEventStream method immediately below will be called to deserialize the event stream.
        try value.deserializeMember(member, self)
    }

    public func readEventStream<E: DeserializableStruct & Sendable>(
        _ schema: Schema
    ) throws -> AsyncThrowingStream<E, any Error> {
        // Get the ReadableStream carrying the event stream data
        guard case .stream(let stream) = response.body else {
            throw SerializerError("Not a streaming body")
        }

        // An unmarshal closure is created that uses the EventTypeDeserializer to unmarshal each event
        // on the stream.  This lets us use schema-based serialization with the existing
        // marshal/unmarshal interface.
        let unmarshalClosure: UnmarshalClosure<E> = { [codec] message in
            let eventUnionDeserializer = EventUnionDeserializer(codec: codec, message: message)
            return try E.deserialize(eventUnionDeserializer)
        }

        // Create a message decoder stream & use that to create the async stream that is returned.
        return DefaultMessageDecoderStream<E>(
            stream: stream,
            messageDecoder: DefaultMessageDecoder(),
            unmarshalClosure: unmarshalClosure
        ).toAsyncStream()
    }

    public var mediaType: String? { "application/vnd.amazon.eventstream" }
}
