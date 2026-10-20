//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
@_spi(SchemaBasedSerde)
import class Smithy.EventPayloadTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
import protocol Smithy.SmithyDocument
import struct SmithyEventStreamsAPI.Header
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer
@_spi(SchemaBasedSerde)
import typealias SmithySerialization.WriteValueConsumer

/// A serializer for the member of an event that is marked with the `@eventPayload` trait.
///
/// This serializer may be passed all of an event's members; only the member marked with the
/// `@eventPayload` trait is serialized, all others are ignored.
///
/// The payload's content type is determined by the type of the payload member:
/// a blob is sent as `application/octet-stream`, a string as `text/plain`, and a structure or
/// union is encoded using the codec for the protocol in use.
/// See https://smithy.io/2.0/spec/streaming.html#eventpayload-trait
final class EventPayloadSerializer: ShapeSerializer {
    let codec: any Codec
    let contentType: String

    /// The serialized event payload.
    private(set) var payload = Data()

    /// The `:content-type` header for the payload, if the payload member was written.
    private(set) var headers: [Header] = []

    init(codec: any Codec, contentType: String) {
        self.codec = codec
        self.contentType = contentType
    }

    func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        guard isEventPayload(schema) else { return }

        // Encode the payload structure or union using a serializer for the protocol in use.
        // The target schema is used so that the payload is written as the root of the
        // payload document, without the member name as a key.
        let payloadSerializer = try codec.makeSerializer()
        try payloadSerializer.writeStruct(schema.target ?? schema, value)
        try setPayload(try payloadSerializer.data ?? Data(), contentType: contentType)
    }

    func writeBlob(_ schema: Schema, _ value: Data) throws {
        guard isEventPayload(schema) else { return }
        try setPayload(value, contentType: "application/octet-stream")
    }

    func writeString(_ schema: Schema, _ value: String) throws {
        guard isEventPayload(schema) else { return }
        try setPayload(Data(value.utf8), contentType: "text/plain")
    }

    func writeList<E>(_ schema: Schema, _ value: [E], _ consumer: WriteValueConsumer<E>) throws {
        try skipOrThrow(schema)
    }

    func writeMap<V>(_ schema: Schema, _ value: [String: V], _ consumer: WriteValueConsumer<V>) throws {
        try skipOrThrow(schema)
    }

    func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        try skipOrThrow(schema)
    }

    func writeByte(_ schema: Schema, _ value: Int8) throws {
        try skipOrThrow(schema)
    }

    func writeShort(_ schema: Schema, _ value: Int16) throws {
        try skipOrThrow(schema)
    }

    func writeInteger(_ schema: Schema, _ value: Int32) throws {
        try skipOrThrow(schema)
    }

    func writeLong(_ schema: Schema, _ value: Int64) throws {
        try skipOrThrow(schema)
    }

    func writeFloat(_ schema: Schema, _ value: Float) throws {
        try skipOrThrow(schema)
    }

    func writeDouble(_ schema: Schema, _ value: Double) throws {
        try skipOrThrow(schema)
    }

    func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        try skipOrThrow(schema)
    }

    func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        try skipOrThrow(schema)
    }

    func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        try skipOrThrow(schema)
    }

    func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws {
        try skipOrThrow(schema)
    }

    func writeNull(_ schema: Schema) throws {
        // A nil payload is sent as an empty payload.
    }

    var data: Data? {
        get throws { payload }
    }

    // todo: replace the headers property with serializer mediaType
    var mediaType: String? { nil }

    // MARK: - Private methods

    private func setPayload(_ payload: Data, contentType: String) throws {
        self.payload = payload
        self.headers = [Header(name: ":content-type", value: .string(contentType))]
    }

    /// Ignores members that are not the event payload, and throws for the payload member if its
    /// type may not be bound to an event payload.
    private func skipOrThrow(_ schema: Schema) throws {
        guard isEventPayload(schema) else { return }
        throw SerializerError(
            "Expected blob, string, structure, or union for @eventPayload member, " +
            "got \(schema.type).  Schema: \(schema.id)"
        )
    }

    private func isEventPayload(_ schema: Schema) -> Bool {
        schema.hasTrait(EventPayloadTrait.self)
    }
}
