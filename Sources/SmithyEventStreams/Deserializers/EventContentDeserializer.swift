//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import class Smithy.EventPayloadTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
import struct SmithyEventStreamsAPI.Message
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.DeserializableStruct
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ThrowByDefaultShapeDeserializer

/// Deserializes the associated value (event or exception) from a case of a streaming union.
class EventContentDeserializer: ThrowByDefaultShapeDeserializer {
    let codec: any Codec
    let message: Message

    init(codec: any Codec, message: Message) {
        self.codec = codec
        self.message = message
    }

    func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws {

        // Deserialize the event payload, to the member marked with @eventPayload if it exists,
        // to the structure's members otherwise.
        // Use a deserializer for the protocol in use, by making it from the codec.
        let payloadDeserializer = try codec.makeDeserializer(data: message.payload)
        if let payloadMember = schema.members.first(where: { $0.hasTrait(EventPayloadTrait.self) }) {
            try value.deserializeMember(payloadMember, payloadDeserializer)
        } else {
            try payloadDeserializer.readStruct(schema, &value)
        }
        self.mediaType = payloadDeserializer.mediaType

        // Attempt to match the headers in the message to members in the structure.
        for header in message.headers {
            guard let headerMember = schema.members.first(where: { $0.id.member == header.name }) else { continue }
            let headerDeserializer = EventHeaderDeserializer(header: header)
            try value.deserializeMember(headerMember, headerDeserializer)
        }
    }

    var mediaType: String?
}
