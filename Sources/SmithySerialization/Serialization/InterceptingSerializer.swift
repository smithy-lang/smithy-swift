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
public protocol InterceptingSerializer: ShapeSerializer {

    /// Selects the serializer to be used for this write operation.
    /// - Parameter schema: The schema that is to be written.
    /// - Returns: The serializer to use when writing this schema.
    func before(_ schema: Schema) throws -> any ShapeSerializer

    /// Called after a write to allow for any needed cleanup
    /// - Parameter schema: The schema that was just written.
    func after(_ schema: Schema) throws
}

// All of the methods in this extension:
// - get the serializer to use by calling the `before(_:)` method
// - perform serialization with that serializer
// - call the `after(_:)` method to clean up
//
// An implementation is provided for every ShapeSerializer `write...` method.
public extension InterceptingSerializer {

    func after(_ schema: Schema) throws {
        // no operation by default
    }

    func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        try before(schema).writeStruct(schema, value)
        try after(schema)
    }

    func writeList<E>(
        _ schema: Schema,
        _ value: [E],
        _ consumer: (E, any ShapeSerializer) throws -> Void
    ) throws {
        try before(schema).writeList(schema, value, consumer)
        try after(schema)
    }

    func writeMap<V>(
        _ schema: Schema,
        _ value: [String: V],
        _ consumer: (V, any ShapeSerializer) throws -> Void
    ) throws {
        try before(schema).writeMap(schema, value, consumer)
        try after(schema)
    }

    func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        try before(schema).writeBoolean(schema, value)
        try after(schema)
    }

    func writeByte(_ schema: Schema, _ value: Int8) throws {
        try before(schema).writeByte(schema, value)
        try after(schema)
    }

    func writeShort(_ schema: Schema, _ value: Int16) throws {
        try before(schema).writeShort(schema, value)
        try after(schema)
    }

    func writeInteger(_ schema: Schema, _ value: Int32) throws {
        try before(schema).writeInteger(schema, value)
        try after(schema)
    }

    func writeLong(_ schema: Schema, _ value: Int64) throws {
        try before(schema).writeLong(schema, value)
        try after(schema)
    }

    func writeFloat(_ schema: Schema, _ value: Float) throws {
        try before(schema).writeFloat(schema, value)
        try after(schema)
    }

    func writeDouble(_ schema: Schema, _ value: Double) throws {
        try before(schema).writeDouble(schema, value)
        try after(schema)
    }

    func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        try before(schema).writeBigInteger(schema, value)
        try after(schema)
    }

    func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        try before(schema).writeBigDecimal(schema, value)
        try after(schema)
    }

    func writeString(_ schema: Schema, _ value: String) throws {
        try before(schema).writeString(schema, value)
        try after(schema)
    }

    func writeBlob(_ schema: Schema, _ value: Data) throws {
        try before(schema).writeBlob(schema, value)
        try after(schema)
    }

    func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        try before(schema).writeTimestamp(schema, value)
        try after(schema)
    }

    func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws {
        try before(schema).writeDocument(schema, value)
        try after(schema)
    }

    func writeDataStream(_ schema: Schema, _ value: ByteStream) throws {
        try before(schema).writeDataStream(schema, value)
        try after(schema)
    }

    func writeEventStream<E: SerializableStruct & Sendable>(
        _ schema: Schema,
        _ value: AsyncThrowingStream<E, any Error>
    ) throws {
        try before(schema).writeEventStream(schema, value)
        try after(schema)
    }

    func writeNull(_ schema: Schema) throws {
        try before(schema).writeNull(schema)
        try after(schema)
    }
}
