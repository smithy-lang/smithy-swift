//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
@_spi(SchemaBasedSerde)
import class Smithy.EventHeaderTrait
@_spi(SchemaBasedSerde)
import class Smithy.EventPayloadTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
import struct SmithyEventStreamsAPI.Header
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.NoOpByDefaultShapeSerializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer

/// Serializes the associated value (an event) of a case of a streaming union to a message.
///
/// The event's members are bound to the message as follows:
/// - Members marked with the `@eventHeader` trait are written to the message headers.
/// - A member marked with the `@eventPayload` trait, if present, is written to the message payload.
/// - If there is no `@eventPayload` member, the members that are not bound to a header are written
///   to the message payload as a structure, using the codec for the protocol in use.
///
/// See https://smithy.io/2.0/spec/streaming.html#event-message-serialization
final class EventContentSerializer: NoOpByDefaultShapeSerializer {
    let codec: any Codec
    let contentType: String

    /// The headers & payload serialized from the event, available after serialization completes.
    private(set) var headers: [Header] = []
    private(set) var payload = Data()

    init(codec: any Codec, contentType: String) {
        self.codec = codec
        self.contentType = contentType
    }

    func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {

        // The member schema for the union case targets the event structure; its members
        // carry the event bindings.
        let eventSchema = schema.target ?? schema

        // Write the members that are bound to event headers.
        // The header serializer ignores any member that isn't marked with @eventHeader.
        let headerSerializer = EventHeaderSerializer()
        try value.serializeMembers(eventSchema, headerSerializer)
        headers = headerSerializer.headers

        if eventSchema.members.contains(where: { $0.hasTrait(EventPayloadTrait.self) }) {
            // Write the single member that is bound to the event payload.
            // The payload serializer ignores all other members & provides the content type
            // that matches the payload member's type.
            let payloadSerializer = EventPayloadSerializer(codec: codec, contentType: contentType)
            try value.serializeMembers(eventSchema, payloadSerializer)
            payload = payloadSerializer.payload
            headers.append(contentsOf: payloadSerializer.headers)
        } else if eventSchema.members.contains(where: { !$0.hasTrait(EventHeaderTrait.self) }) {
            // There is no @eventPayload member, so write the members that are not bound to a
            // header as a structure, using a serializer for the protocol in use.
            let payloadSerializer = try codec.makeSerializer()
            let unboundValue = UnboundMembers(value: value)
            try payloadSerializer.writeStruct(eventSchema, unboundValue)
            payload = try payloadSerializer.data ?? Data()
            headers.append(Header(name: ":content-type", value: .string(contentType)))
        }
    }

    var mediaType: String? { nil }
}

/// Wraps an event so that the members bound to event headers are left out of the event payload.
private struct UnboundMembers<S: SerializableStruct>: SerializableStruct {
    let value: S

    func serialize(_ serializer: any ShapeSerializer) throws {
        throw SerializerError("Not implemented")
    }

    func serializeMembers(_ schema: Schema, _ serializer: any ShapeSerializer) throws {
        try value.serializeMembers(schema, UnboundMemberSerializer(base: serializer))
    }
}
