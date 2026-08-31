//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import enum Smithy.ClientError
@_spi(SchemaBasedSerde)
import class Smithy.Schema
import protocol Smithy.SmithyDocument
import struct SmithyEventStreamsAPI.Header
import struct SmithyEventStreamsAPI.Message
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.NoOpByDefaultShapeSerializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct

/// A serializer that is used to serialize an event stream union to an event stream message.
///
/// Only use this serializer for event stream unions.  Serializing any other type will result in a
/// "not implemented" error.
///
/// The case of the union that is serialized determines the `:event-type` header, and its associated
/// value is serialized to the message's headers & payload.  The `sdkUnknown` case cannot be
/// serialized and results in an error.
final class EventUnionSerializer: NoOpByDefaultShapeSerializer {
    let codec: any Codec
    let contentType: String

    /// The message that the union was serialized to, available after serialization completes.
    private(set) var message = Message()

    init(codec: any Codec, contentType: String) {
        self.codec = codec
        self.contentType = contentType
    }

    func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {

        // The union serializes exactly one of its members: the case that is set.
        // The event serializer below captures that member & its serialized content.
        let eventSerializer = EventSerializer(codec: codec, contentType: contentType)
        try value.serializeMembers(schema, eventSerializer)

        guard let eventType = eventSerializer.eventType else {
            // The only union case with no member schema is sdkUnknown, which cannot be sent.
            throw ClientError.unknownError("cannot serialize the unknown event type!")
        }

        var headers = [
            Header(name: ":message-type", value: .string("event")),
            Header(name: ":event-type", value: .string(eventType)),
        ]
        headers.append(contentsOf: eventSerializer.headers)
        message = Message(headers: headers, payload: eventSerializer.payload)
    }

    var mediaType: String? { nil }
}

/// Serializes the event that is the associated value of the streaming union's selected case.
///
/// A union writes only the member for the case that is set, so the event type is taken from the
/// name of the single member written to this serializer.
private final class EventSerializer: NoOpByDefaultShapeSerializer {
    let codec: any Codec
    let contentType: String

    /// The member name of the union case that was serialized, which names the event type.
    private(set) var eventType: String?
    private(set) var headers: [Header] = []
    private(set) var payload = Data()

    init(codec: any Codec, contentType: String) {
        self.codec = codec
        self.contentType = contentType
    }

    func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        eventType = schema.memberName

        // Serialize the event's members to the message headers & payload.
        let contentSerializer = EventContentSerializer(codec: codec, contentType: contentType)
        try contentSerializer.writeStruct(schema, value)
        headers = contentSerializer.headers
        payload = contentSerializer.payload
    }

    func writeString(_ schema: Schema, _ value: String) throws {
        // The sdkUnknown case of a union writes a string; it is not a valid event & is
        // detected by the absence of an event type in EventUnionSerializer.
    }

    var mediaType: String? { nil }
}
