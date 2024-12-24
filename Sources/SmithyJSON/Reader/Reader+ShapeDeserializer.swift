//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import struct Smithy.Document
import enum SmithyReadWrite.ReaderError
@_spi(SchemaBasedSerde) import protocol SmithyReadWrite.ShapeDeserializer
@_spi(SchemaBasedSerde) import protocol SmithyReadWrite.SchemaProtocol
@_spi(SchemaBasedSerde) import protocol SmithyReadWrite.DeserializableShape
@_spi(SchemaBasedSerde) import class SmithyReadWrite.StructureSchema
@_spi(SchemaBasedSerde) import class SmithyReadWrite.ListSchema
@_spi(SchemaBasedSerde) import class SmithyReadWrite.MapSchema
@_spi(SchemaBasedSerde) import class SmithyReadWrite.SimpleSchema
@_spi(SmithyTimestamps) import enum SmithyTimestamps.TimestampFormat

@_spi(SchemaBasedSerde)
extension Reader: SmithyReadWrite.ShapeDeserializer {

    public func readStructure<Base: SmithyReadWrite.DeserializableShape>(
        schema: SmithyReadWrite.StructureSchema<Base>
    ) throws -> Base? {
        // TODO: Implement me
        return Base()
    }

    public func readString(schema: SmithyReadWrite.SchemaProtocol) throws -> String? {
        try readIfPresent()
    }

    public func readList<T>(schema: SmithyReadWrite.ListSchema<T>) throws -> [T]? {
        // TODO: Implement me
        []
    }

    public func readMap<T>(schema: SmithyReadWrite.MapSchema<T>) throws -> [String : T]? {
        // TODO: Implement me
        [:]
    }

    public func readBoolean(schema: any SmithyReadWrite.SchemaProtocol) throws -> Bool? {
        try readIfPresent()
    }

    public func readByte(schema: any SmithyReadWrite.SchemaProtocol) throws -> Int8? {
        try readIfPresent()
    }

    public func readShort(schema: any SmithyReadWrite.SchemaProtocol) throws -> Int16? {
        try readIfPresent()
    }

    public func readInteger(schema: any SmithyReadWrite.SchemaProtocol) throws -> Int? {
        try readIfPresent()
    }

    public func readLong(schema: any SmithyReadWrite.SchemaProtocol) throws -> Int? {
        try readIfPresent()
    }

    public func readFloat(schema: any SmithyReadWrite.SchemaProtocol) throws -> Float? {
        try readIfPresent()
    }

    public func readDouble(schema: any SmithyReadWrite.SchemaProtocol) throws -> Double? {
        try readIfPresent()
    }

    public func readBigInteger(schema: any SmithyReadWrite.SchemaProtocol) throws -> Int? {
        try readIfPresent()
    }

    public func readBigDecimal(schema: any SmithyReadWrite.SchemaProtocol) throws -> Float? {
        try readIfPresent()
    }

    public func readBlob(schema: any SmithyReadWrite.SchemaProtocol) throws -> Data? {
        try readIfPresent()
    }

    public func readTimestamp(schema: SmithyReadWrite.SimpleSchema<Date>) throws -> Date? {
        // TODO: Implement me
        try readTimestampIfPresent(format: schema.timestampFormat ?? .epochSeconds)
    }

    public func readDocument(schema: any SmithyReadWrite.SchemaProtocol) throws -> Document? {
        // TODO: Implement me
        nil
    }

    public func readNull(schema: any SmithyReadWrite.SchemaProtocol) throws -> Bool? {
        // TODO: Implement me
        return false
    }
}
