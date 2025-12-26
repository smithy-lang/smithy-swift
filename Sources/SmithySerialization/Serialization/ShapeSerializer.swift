//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import enum Smithy.ByteStream
import class Smithy.Schema
import protocol Smithy.SmithyDocument

public protocol ShapeSerializer {
    func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws
    func writeList<E>(_ schema: Schema, _ value: [E], _ consumer: WriteValueConsumer<E>) throws
    func writeMap<V>(_ schema: Schema, _ value: [String: V], _ consumer: WriteValueConsumer<V>) throws
    func writeBoolean(_ schema: Schema, _ value: Bool) throws
    func writeByte(_ schema: Schema, _ value: Int8) throws
    func writeShort(_ schema: Schema, _ value: Int16) throws
    func writeInteger(_ schema: Schema, _ value: Int) throws
    func writeLong(_ schema: Schema, _ value: Int) throws
    func writeFloat(_ schema: Schema, _ value: Float) throws
    func writeDouble(_ schema: Schema, _ value: Double) throws
    func writeBigInteger(_ schema: Schema, _ value: Int64) throws
    func writeBigDecimal(_ schema: Schema, _ value: Double) throws
    func writeString(_ schema: Schema, _ value: String) throws
    func writeBlob(_ schema: Schema, _ value: Foundation.Data) throws
    func writeTimestamp(_ schema: Schema, _ value: Foundation.Date) throws
    func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws
    func writeNull(_ schema: Schema) throws
    func writeDataStream(_ schema: Schema, _ value: ByteStream) throws
    func writeEventStream<E: SerializableStruct>(_ schema: Schema, _ value: AsyncThrowingStream<E, any Error>) throws

    var data: Foundation.Data { get }
}

public extension ShapeSerializer {
    
    /// Writes a Smithy enum.
    /// - Parameters:
    ///   - schema: The schema for the Smithy Enum.
    ///   - value: The enum value to be written.
    func writeEnum<T: RawRepresentable>(_ schema: Schema, _ value: T) throws where T.RawValue == String {
        try writeString(schema, value.rawValue)
    }

    /// Writes an Smithy IntEnum.
    /// - Parameters:
    ///   - schema: The schema for the Smithy IntEnum.
    ///   - value: The enum value to be written.
    func writeIntEnum<T: RawRepresentable>(_ schema: Schema, _ value: T) throws where T.RawValue == Int {
        try writeInteger(schema, value.rawValue)
    }
    
    /// Write a sparse list.
    ///
    /// The compiler will resolve to this `writeList` overload when a list's element type is optional.  No need to reference the `@sparse` trait.
    /// - Parameters:
    ///   - schema: The list schema.
    ///   - value: The sparse list to be written.
    ///   - consumer: The `WriteValueConsumer` for the non-optional element type.
    func writeList<E>(_ schema: Schema, _ value: [E?], _ consumer: WriteValueConsumer<E>) throws {
        try writeList(schema, value) { element, serializer in
            if let element {
                try consumer(element, serializer)
            } else {
                try serializer.writeNull(schema.members[0])
            }
        }
    }
    
    /// Write a sparse map.
    ///
    /// The compiler will resolve to this `writeMap` overload when a map's value type is optional.  No need to reference the `@sparse` trait.
    /// - Parameters:
    ///   - schema: The map schema.
    ///   - value: The sparse map to be written.
    ///   - consumer: The `WriteValueConsumer` for the non-optional element type.
    func writeMap<V>(_ schema: Schema, _ value: [String: V?], _ consumer: WriteValueConsumer<V>) throws {
        try writeMap(schema, value) { element, serializer in
            if let element {
                try consumer(element, serializer)
            } else {
                try serializer.writeNull(schema.members[1])
            }
        }
    }
    
    /// Write a Smithy document.
    ///
    /// Based on the type of the document, the contents are written using the appropriate `write...` method for its contents.
    /// - Parameters:
    ///   - schema: The schema for the document
    ///   - value: The document to be written
    func writeDocument(_ schema: Smithy.Schema, _ value: any Smithy.SmithyDocument) throws {
        switch value.type {
        case .blob:
            try writeBlob(schema, value.asBlob())
        case .boolean:
            try writeBoolean(schema, value.asBoolean())
        case .string:
            try writeString(schema, value.asString())
        case .timestamp:
            try writeTimestamp(schema, value.asTimestamp())
        case .byte:
            try writeByte(schema, value.asByte())
        case .short:
            try writeShort(schema, value.asShort())
        case .integer:
            try writeInteger(schema, value.asInteger())
        case .long:
            try writeLong(schema, Int(value.asLong()))
        case .float:
            try writeFloat(schema, value.asFloat())
        case .double:
            try writeDouble(schema, value.asDouble())
        case .bigDecimal:
            try writeBigDecimal(schema, value.asBigDecimal())
        case .bigInteger:
            try writeBigInteger(schema, value.asBigInteger())
        case .list, .set:
            let list = try value.asList()
            try writeList(schema, list) { element, serializer in
                try serializer.writeDocument(schema.members[0], element)
            }
        case .map:
            let map = try value.asStringMap()
            try writeMap(schema, map) { value, serializer in
                try serializer.writeDocument(schema.members[1], value)
            }
        case .document, .enum, .intEnum, .structure, .union, .member, .service, .resource, .operation:
            throw SerializerError("Unsupported or invalid document type: \(value.type)")
        }
    }

    func writeDataStream(_ schema: Schema, _ value: ByteStream) throws {
        // by default, do nothing
    }

    func writeEventStream<E: SerializableStruct>(_ schema: Schema, _ value: AsyncThrowingStream<E, any Error>) throws {
        // by default, do nothing
    }
}
