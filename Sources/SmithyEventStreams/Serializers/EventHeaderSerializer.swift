//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
@_spi(SchemaBasedSerde)
import class Smithy.EventHeaderTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
import protocol Smithy.SmithyDocument
import struct SmithyEventStreamsAPI.Header
import enum SmithyEventStreamsAPI.HeaderValue
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer
@_spi(SchemaBasedSerde)
import typealias SmithySerialization.WriteValueConsumer

/// A serializer for event stream data that is bound to event headers.
///
/// This serializer may be passed all of an event's members; members that are not marked with the
/// `@eventHeader` trait are ignored.  A member that is marked with `@eventHeader` but has a type
/// that cannot be bound to an event header will throw a "not implemented" error.
///
/// After serialization, the headers written by this serializer are available in `headers`.
final class EventHeaderSerializer: ShapeSerializer {

    /// The event headers that were written to this serializer, in the order they were written.
    private(set) var headers: [Header] = []

    func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        try skipOrThrow(schema)
    }

    func writeList<E>(_ schema: Schema, _ value: [E], _ consumer: WriteValueConsumer<E>) throws {
        try skipOrThrow(schema)
    }

    func writeMap<V>(_ schema: Schema, _ value: [String: V], _ consumer: WriteValueConsumer<V>) throws {
        try skipOrThrow(schema)
    }

    func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        try append(schema, .bool(value))
    }

    func writeByte(_ schema: Schema, _ value: Int8) throws {
        try append(schema, .byte(value))
    }

    func writeShort(_ schema: Schema, _ value: Int16) throws {
        try append(schema, .int16(value))
    }

    func writeInteger(_ schema: Schema, _ value: Int32) throws {
        try append(schema, .int32(value))
    }

    func writeLong(_ schema: Schema, _ value: Int64) throws {
        try append(schema, .int64(value))
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

    func writeString(_ schema: Schema, _ value: String) throws {
        try append(schema, .string(value))
    }

    func writeBlob(_ schema: Schema, _ value: Data) throws {
        try append(schema, .byteArray(value))
    }

    func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        try append(schema, .timestamp(value))
    }

    func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws {
        try skipOrThrow(schema)
    }

    func writeNull(_ schema: Schema) throws {
        // A nil header is simply omitted from the message.
    }

    var data: Data? {
        get throws { nil }
    }

    var mediaType: String? { nil }

    // MARK: - Private methods

    /// Appends a header for the passed member schema & value, if the member is bound to an event header.
    private func append(_ schema: Schema, _ value: HeaderValue) throws {
        guard isEventHeader(schema) else { return }
        guard let name = schema.memberName else {
            throw SerializerError("Event header must be a structure member.  Schema: \(schema.id)")
        }
        headers.append(Header(name: name, value: value))
    }

    /// Ignores members that are not bound to an event header, and throws for those that are,
    /// since a member of this type cannot be written to an event header.
    private func skipOrThrow(_ schema: Schema) throws {
        guard isEventHeader(schema) else { return }
        throw SerializerError("Cannot write type \(schema.type) to an event header.  Schema: \(schema.id)")
    }

    private func isEventHeader(_ schema: Schema) -> Bool {
        schema.hasTrait(EventHeaderTrait.self)
    }
}
