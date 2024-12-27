//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import struct Smithy.Document
import protocol Smithy.SmithyDocument
import enum SmithyReadWrite.ReaderError
@_spi(SchemaBasedSerde) import protocol SmithyReadWrite.ShapeDeserializer
@_spi(SchemaBasedSerde) import protocol SmithyReadWrite.SchemaProtocol
@_spi(SchemaBasedSerde) import protocol SmithyReadWrite.DeserializableShape
@_spi(SchemaBasedSerde) import class SmithyReadWrite.Schema
@_spi(SmithyTimestamps) import enum SmithyTimestamps.TimestampFormat

@_spi(SchemaBasedSerde)
extension Reader: SmithyReadWrite.ShapeDeserializer {

    public func readStructure<Target: SmithyReadWrite.DeserializableShape>(
        schema: SmithyReadWrite.Schema<Target>
    ) throws -> Target? {
        // TODO: Implement me
        guard self.hasContent else { return nil }
        var value = Target()
        try schema.members.forEach { memberContainer in
            let memberSchema = memberContainer.member.memberSchema
            guard let targetSchema = memberSchema.targetSchema() else {
                throw ReaderError.requiredValueNotPresent
            }
            let resolvedName = try resolvedName(memberSchema: memberSchema)
            guard let resolvedName = memberSchema.jsonName ?? memberSchema.memberName else {
                throw ReaderError.requiredValueNotPresent
            }
            let resolvedReader = self[NodeInfo(resolvedName)]
            guard resolvedReader.hasContent else { return }
            var resolvedDefault = targetSchema.defaultValue ?? memberSchema.defaultValue
            if memberSchema.isRequired {
                resolvedDefault = try resolvedDefault ?? targetSchema.lastResortDefaultValue
            }
            try memberContainer.performRead(base: &value, reader: resolvedReader)
        }
        return value
    }

    private func resolvedName(memberSchema: SmithyReadWrite.SchemaProtocol) throws -> String {
        if respectsJSONName {
            guard let resolvedName = memberSchema.jsonName ?? memberSchema.memberName else {
                throw ReaderError.requiredValueNotPresent
            }
            return resolvedName
        } else {
            guard let resolvedName = memberSchema.memberName else {
                throw ReaderError.requiredValueNotPresent
            }
            return resolvedName
        }
    }

    public func readString(schema: SmithyReadWrite.Schema<String>) throws -> String? {
        try readIfPresent()
    }

    public func readList<T>(schema: SmithyReadWrite.Schema<[T]>) throws -> [T]? {
        guard hasContent, jsonNode == .array else { return nil }
        guard let memberContainer = schema.members.first(where: { $0.member.memberSchema.memberName == "member" }) else {
            throw ReaderError.requiredValueNotPresent
        }
        var value = [T]()
        try children.forEach { reader in
            try memberContainer.performRead(base: &value, reader: reader)
        }
        return value
    }

    public func readMap<T>(schema: SmithyReadWrite.Schema<[String: T]>) throws -> [String : T]? {
        guard hasContent, jsonNode == .object else { return nil }
        guard let keyContainer = schema.members.first(where: { $0.member.memberSchema.memberName == "key" }) else {
            throw ReaderError.requiredValueNotPresent
        }
        guard let valueContainer = schema.members.first(where: { $0.member.memberSchema.memberName == "value" }) else {
            throw ReaderError.requiredValueNotPresent
        }
        var value = [String: T]()
        try children.forEach { reader in
            var temp = [String: T]()
            try valueContainer.performRead(base: &temp, reader: reader)
            value[reader.nodeInfo.name] = temp["value"]
        }
        return value
    }

    public func readBoolean(schema: SmithyReadWrite.Schema<Bool>) throws -> Bool? {
        try readIfPresent()
    }

    public func readByte(schema: SmithyReadWrite.Schema<Int8>) throws -> Int8? {
        try readIfPresent()
    }

    public func readShort(schema: SmithyReadWrite.Schema<Int16>) throws -> Int16? {
        try readIfPresent()
    }

    public func readInteger(schema: SmithyReadWrite.Schema<Int>) throws -> Int? {
        try readIfPresent()
    }

    public func readLong(schema: SmithyReadWrite.Schema<Int>) throws -> Int? {
        try readIfPresent()
    }

    public func readFloat(schema: SmithyReadWrite.Schema<Float>) throws -> Float? {
        try readIfPresent()
    }

    public func readDouble(schema: SmithyReadWrite.Schema<Double>) throws -> Double? {
        try readIfPresent()
    }

    public func readBigInteger(schema: SmithyReadWrite.Schema<Int>) throws -> Int? {
        try readIfPresent()
    }

    public func readBigDecimal(schema: SmithyReadWrite.Schema<Double>) throws -> Double? {
        try readIfPresent()
    }

    public func readBlob(schema: SmithyReadWrite.Schema<Data>) throws -> Data? {
        try readIfPresent()
    }

    public func readTimestamp(schema: SmithyReadWrite.Schema<Date>) throws -> Date? {
        try readTimestampIfPresent(format: schema.timestampFormat ?? .epochSeconds)
    }

    public func readDocument(schema: SmithyReadWrite.Schema<Document>) throws -> Document? {
        try readIfPresent()
    }

    public func readNull(schema: any SmithyReadWrite.SchemaProtocol) throws -> Bool? {
        try readNullIfPresent()
    }
}
