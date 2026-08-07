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
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer
@_spi(SchemaBasedSerde)
import typealias SmithySerialization.WriteValueConsumer

/// Serializes an event's members to the event payload, omitting the members that are bound
/// to event headers.
///
/// All writes are forwarded to the serializer for the protocol in use, except for those of
/// members marked with the `@eventHeader` trait, which are dropped because they have already
/// been written to the message's headers.
///
/// This filtering is only needed for the event's own members; nested shapes within the payload
/// cannot have event bindings, so they are written directly by the underlying serializer.
struct UnboundMemberSerializer: ShapeSerializer {
    let base: any ShapeSerializer

    func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeStruct(schema, value)
    }

    func writeList<E>(_ schema: Schema, _ value: [E], _ consumer: WriteValueConsumer<E>) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeList(schema, value, consumer)
    }

    func writeMap<V>(_ schema: Schema, _ value: [String: V], _ consumer: WriteValueConsumer<V>) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeMap(schema, value, consumer)
    }

    func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeBoolean(schema, value)
    }

    func writeByte(_ schema: Schema, _ value: Int8) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeByte(schema, value)
    }

    func writeShort(_ schema: Schema, _ value: Int16) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeShort(schema, value)
    }

    func writeInteger(_ schema: Schema, _ value: Int32) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeInteger(schema, value)
    }

    func writeLong(_ schema: Schema, _ value: Int64) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeLong(schema, value)
    }

    func writeFloat(_ schema: Schema, _ value: Float) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeFloat(schema, value)
    }

    func writeDouble(_ schema: Schema, _ value: Double) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeDouble(schema, value)
    }

    func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeBigInteger(schema, value)
    }

    func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeBigDecimal(schema, value)
    }

    func writeString(_ schema: Schema, _ value: String) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeString(schema, value)
    }

    func writeBlob(_ schema: Schema, _ value: Data) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeBlob(schema, value)
    }

    func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeTimestamp(schema, value)
    }

    func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeDocument(schema, value)
    }

    func writeNull(_ schema: Schema) throws {
        guard !isEventHeader(schema) else { return }
        try base.writeNull(schema)
    }

    var data: Data {
        get throws { try base.data }
    }

    private func isEventHeader(_ schema: Schema) -> Bool {
        schema.hasTrait(EventHeaderTrait.self)
    }
}
