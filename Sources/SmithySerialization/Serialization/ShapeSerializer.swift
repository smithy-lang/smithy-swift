//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import enum Smithy.ByteStream
import enum Smithy.Prelude
import struct Smithy.Schema
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
    func writeBlob(_ schema: Schema, _ value: Data) throws
    func writeTimestamp(_ schema: Schema, _ value: Date) throws
    func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws
    func writeNull(_ schema: Schema) throws
    func writeDataStream(_ schema: Schema, _ value: ByteStream) throws
    func writeEventStream<E: SerializableStruct>(_ schema: Schema, _ value: AsyncThrowingStream<E, any Error>) throws

    var data: Data { get throws }
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
    /// Generated code will call this method when the list has the sparse trait.
    /// - Parameters:
    ///   - schema: The member schema targeting the list.
    ///   - value: The sparse list to be written.
    ///   - consumer: The `WriteValueConsumer` for the non-optional element type.
    func writeSparseList<E>(_ schema: Schema, _ value: [E?], _ consumer: WriteValueConsumer<E>) throws {
        try writeList(schema, value) { element, serializer in
            if let element {
                try consumer(element, serializer)
            } else {
                try serializer.writeNull(schema.resolveTarget.member)
            }
        }
    }

    /// Write a sparse map.
    ///
    /// Generated code will call this method when the map has the sparse trait.
    /// - Parameters:
    ///   - schema: The member schema targeting the map.
    ///   - value: The sparse map to be written.
    ///   - consumer: The `WriteValueConsumer` for the non-optional element type.
    func writeSparseMap<V>(_ schema: Schema, _ value: [String: V?], _ consumer: WriteValueConsumer<V>) throws {
        try writeMap(schema, value) { element, serializer in
            if let element {
                try consumer(element, serializer)
            } else {
                try serializer.writeNull(schema.resolveTarget.value)
            }
        }
    }

    /// Write a Smithy document.
    ///
    /// Based on the type of the document, the contents are written using the appropriate `write...` method for its contents.
    /// - Parameters:
    ///   - schema: The schema for the document
    ///   - value: The document to be written
    func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws {
//        throw SerializerError("Not implemented")
        switch value.type {
        case .blob:
            try writeBlob(Prelude.blobSchema, value.asBlob())
        case .boolean:
            try writeBoolean(Prelude.booleanSchema, value.asBoolean())
        case .string:
            try writeString(Prelude.stringSchema, value.asString())
        case .timestamp:
            try writeTimestamp(Prelude.timestampSchema, value.asTimestamp())
        case .byte:
            try writeByte(Prelude.byteSchema, value.asByte())
        case .short:
            try writeShort(Prelude.shortSchema, value.asShort())
        case .integer:
            try writeInteger(Prelude.integerSchema, value.asInteger())
        case .long:
            try writeLong(Prelude.longSchema, Int(value.asLong()))
        case .float:
            try writeFloat(Prelude.floatSchema, value.asFloat())
        case .double:
            try writeDouble(Prelude.doubleSchema, value.asDouble())
        case .bigDecimal:
            try writeBigDecimal(Prelude.bigDecimalSchema, value.asBigDecimal())
        case .bigInteger:
            try writeBigInteger(Prelude.bigIntegerSchema, value.asBigInteger())
        case .list, .set:
            try writeList(Prelude.listDocumentSchema, value.asList()) { element, serializer in
                try serializer.writeDocument(Prelude.listDocumentSchema.member, element)
            }
        case .map:
            try writeMap(Prelude.mapDocumentSchema, value.asStringMap()) { value, serializer in
                try serializer.writeDocument(Prelude.mapDocumentSchema.value, value)
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

extension Schema {

    var resolveMember: Schema? {
        type == .member ? self : nil
    }

    var resolveTarget: Schema {
        if let target {
            return target
        } else {
            return self
        }
    }
}
