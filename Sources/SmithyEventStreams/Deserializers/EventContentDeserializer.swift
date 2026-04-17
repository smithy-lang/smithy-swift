//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import struct Smithy.Document
import struct Smithy.EventHeaderTrait
import struct Smithy.EventPayloadTrait
import struct Smithy.Schema
import struct SmithyEventStreamsAPI.Message
import protocol SmithySerialization.Codec
import protocol SmithySerialization.DeserializableStruct
import struct SmithySerialization.SerializerError
import protocol SmithySerialization.ShapeDeserializer

/// Deserializes the associated value (event or exception) from a case of a streaming union.
struct EventContentDeserializer: ShapeDeserializer {
    let codec: any Codec
    let message: Message

    func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws {

        // Deserialize the event payload, to the member marked with @eventPayload if it exists,
        // to the structure's members otherwise.
        // Use a deserializer for the protocol in use, by making it from the codec.
        let payloadDeserializer = try codec.makeDeserializer(data: message.payload)
        if let payloadMember = schema.members.first(where: { $0.hasTrait(EventPayloadTrait.self) }) {
            try T.readConsumer(payloadMember, &value, payloadDeserializer)
        } else {
            try payloadDeserializer.readStruct(schema, &value)
        }

        // Attempt to match the headers in the message to members in the structure.
        for header in message.headers {
            guard let headerMember = schema.members.first(where: { $0.id.member == header.name }) else { continue }
            let headerDeserializer = EventHeaderDeserializer(header: header)
            try T.readConsumer(headerMember, &value, headerDeserializer)
        }
    }

    func readList<E>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> E) throws -> [E] {
        throw notImplemented
    }

    func readMap<V>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> V) throws -> [String: V] {
        throw notImplemented
    }

    func readBoolean(_ schema: Schema) throws -> Bool {
        throw notImplemented
    }

    func readBlob(_ schema: Schema) throws -> Data {
        throw notImplemented
    }

    func readByte(_ schema: Schema) throws -> Int8 {
        throw notImplemented
    }

    func readShort(_ schema: Schema) throws -> Int16 {
        throw notImplemented
    }

    func readInteger(_ schema: Schema) throws -> Int {
        throw notImplemented
    }

    func readLong(_ schema: Schema) throws -> Int {
        throw notImplemented
    }

    func readFloat(_ schema: Schema) throws -> Float {
        throw notImplemented
    }

    func readDouble(_ schema: Schema) throws -> Double {
        throw notImplemented
    }

    func readBigInteger(_ schema: Schema) throws -> Int64 {
        throw notImplemented
    }

    func readBigDecimal(_ schema: Schema) throws -> Double {
        throw notImplemented
    }

    func readString(_ schema: Schema) throws -> String {
        throw notImplemented
    }

    func readDocument(_ schema: Schema) throws -> Document {
        throw notImplemented
    }

    func readTimestamp(_ schema: Schema) throws -> Date {
        throw notImplemented
    }

    func readNull<T>(_ schema: Schema) throws -> T? {
        throw notImplemented
    }

    func isNull() throws -> Bool {
        throw notImplemented
    }

    var containerSize: Int { -1 }

    private var notImplemented: SerializerError { .init("Not implemented") }
}
