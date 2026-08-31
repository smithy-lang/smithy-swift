//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import enum Smithy.ByteStream
@_spi(SchemaBasedSerde)
import class Smithy.Schema
import protocol Smithy.SmithyDocument
@_spi(SchemaBasedSerde)
import class Smithy.StreamingTrait
import typealias SmithyEventStreamsAPI.MarshalClosure
import struct SmithyEventStreamsAPI.Message
import protocol SmithyEventStreamsAPI.MessageEncoder
import protocol SmithyEventStreamsAuthAPI.MessageSigner
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer
@_spi(SchemaBasedSerde)
import typealias SmithySerialization.WriteValueConsumer

/// A serializer that may be used to serialize an event stream to a request.
///
/// This serializer should only be used on an input structure.  It will only serialize the
/// event stream on the input, nothing else.  If the input structure has no event stream
/// member, it will throw an error.
/// It will throw a "not implemented" error if serialization of any other type is attempted.
@_spi(SchemaBasedSerde)
public final class EventStreamSerializer: ShapeSerializer {
    let codec: any Codec
    let contentType: String
    let messageEncoder: MessageEncoder
    let messageSigner: MessageSigner
    let initialRequestMessage: Message?

    /// The request body carrying the encoded, signed event stream, available after serialization.
    private(set) public var body: ByteStream = .noStream

    public init(
        codec: any Codec,
        contentType: String,
        messageEncoder: MessageEncoder,
        messageSigner: MessageSigner,
        initialRequestMessage: Message? = nil
    ) {
        self.codec = codec
        self.contentType = contentType
        self.messageEncoder = messageEncoder
        self.messageSigner = messageSigner
        self.initialRequestMessage = initialRequestMessage
    }

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {

        // Locate the event stream member on this structure.
        guard schema.members.contains(where: { $0.type == .union && $0.hasTrait(StreamingTrait.self) }) else {
            throw SerializerError("Streaming request sent but no event streaming member")
        }

        // Serialize the input's members with this same serializer.
        // The writeEventStream method immediately below will be called to serialize the event stream;
        // all other members are ignored because they are not part of the event stream body.
        try value.serializeMembers(schema, self)
    }

    public func writeEventStream<E: SerializableStruct & Sendable>(
        _ schema: Schema,
        _ value: AsyncThrowingStream<E, any Error>
    ) throws {

        // A marshal closure is created that uses the EventUnionSerializer to marshal each event
        // on the stream.  This lets us use schema-based serialization with the existing
        // marshal/unmarshal interface.
        let codec = self.codec
        let contentType = self.contentType
        let marshalClosure: MarshalClosure<E> = { event in
            let eventUnionSerializer = EventUnionSerializer(codec: codec, contentType: contentType)
            try event.serialize(eventUnionSerializer)
            return eventUnionSerializer.message
        }

        // Create a message encoder stream & use that as the body of the request.
        body = .stream(DefaultMessageEncoderStream<E>(
            stream: value,
            messageEncoder: messageEncoder,
            marshalClosure: marshalClosure,
            messageSigner: messageSigner,
            initialRequestMessage: initialRequestMessage
        ))
    }

    public func writeList<E>(_ schema: Schema, _ value: [E], _ consumer: WriteValueConsumer<E>) throws {
        // Members other than the event stream are not part of the event stream body.
    }

    public func writeMap<V>(_ schema: Schema, _ value: [String: V], _ consumer: WriteValueConsumer<V>) throws {
        // Members other than the event stream are not part of the event stream body.
    }

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        // Members other than the event stream are not part of the event stream body.
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        // Members other than the event stream are not part of the event stream body.
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        // Members other than the event stream are not part of the event stream body.
    }

    public func writeInteger(_ schema: Schema, _ value: Int32) throws {
        // Members other than the event stream are not part of the event stream body.
    }

    public func writeLong(_ schema: Schema, _ value: Int64) throws {
        // Members other than the event stream are not part of the event stream body.
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        // Members other than the event stream are not part of the event stream body.
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        // Members other than the event stream are not part of the event stream body.
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        // Members other than the event stream are not part of the event stream body.
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        // Members other than the event stream are not part of the event stream body.
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        // Members other than the event stream are not part of the event stream body.
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        // Members other than the event stream are not part of the event stream body.
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        // Members other than the event stream are not part of the event stream body.
    }

    public func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws {
        // Members other than the event stream are not part of the event stream body.
    }

    public func writeNull(_ schema: Schema) throws {
        // Members other than the event stream are not part of the event stream body.
    }

    public var data: Data {
        get throws { throw SerializerError("Not implemented") }
    }
}
