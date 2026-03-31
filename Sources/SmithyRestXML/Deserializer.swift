//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import struct Smithy.Document
import struct Smithy.Schema
import struct Smithy.TimestampFormatTrait
import struct Smithy.XmlAttributeTrait
import struct Smithy.XmlFlattenedTrait
import struct Smithy.XmlNameTrait
import protocol SmithySerialization.DeserializableStruct
import typealias SmithySerialization.ReadStructConsumer
import typealias SmithySerialization.ReadValueConsumer
import struct SmithySerialization.SerializerError
import protocol SmithySerialization.ShapeDeserializer
@_spi(SmithyReadWrite) import class SmithyXML.Reader
@_spi(SmithyReadWrite) import struct SmithyXML.NodeInfo
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter
@_spi(SmithyTimestamps) import enum SmithyTimestamps.TimestampFormat

public struct Deserializer: ShapeDeserializer {
    let reader: Reader

    public init(data: Data) throws {
        if data.isEmpty {
            self.reader = try Reader.from(data: Data("<empty/>".utf8))
        } else {
            self.reader = try Reader.from(data: data)
        }
    }

    init(reader: Reader) {
        self.reader = reader
    }

    private func targetSchema(_ schema: Schema) -> Schema {
        schema.target ?? schema
    }

    public func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws {
        let structSchema: Schema
        switch schema.type {
        case .structure, .union:
            structSchema = schema
        case .member:
            guard let target = schema.target else {
                throw XMLDeserializerError("Expected non-nil target on \(schema)")
            }
            structSchema = target
        default:
            throw XMLDeserializerError("unexpected schema type \(schema.type) used with readStruct")
        }

        for member in structSchema.members {
            let elementName = xmlElementName(for: member)
            let isAttribute = member.hasTrait(XmlAttributeTrait.self)
            let childReader: Reader
            if isAttribute {
                childReader = reader[NodeInfo(elementName, location: .attribute)]
            } else {
                childReader = reader[NodeInfo(elementName)]
            }
            guard childReader.hasContent || !childReader.children.isEmpty else { continue }
            do {
                let memberDeserializer = Deserializer(reader: childReader)
                try T.readConsumer(member, &value, memberDeserializer)
            } catch is DecodedNull {
                // skip null
            }
        }
    }

    public func readList<E>(_ schema: Schema, _ consumer: ReadValueConsumer<E>) throws -> [E] {
        let isFlattened = schema.hasTrait(XmlFlattenedTrait.self)
        var list = [E]()

        if isFlattened {
            let elementName = xmlElementName(for: schema)
            let siblings = (reader.parent?.children ?? [reader]).filter {
                $0.nodeInfo.name == elementName
            }
            guard !siblings.isEmpty else { return list }
            for sibling in siblings {
                let element = try consumer(Deserializer(reader: sibling))
                list.append(element)
            }
        } else {
            let memberSchema = targetSchema(schema).member
            let memberName = xmlElementName(for: memberSchema)
            let members = reader.children.filter { $0.nodeInfo.name == memberName }
            for member in members {
                let element = try consumer(Deserializer(reader: member))
                list.append(element)
            }
        }
        return list
    }

    public func readMap<V>(_ schema: Schema, _ consumer: ReadValueConsumer<V>) throws -> [String: V] {
        let isFlattened = schema.hasTrait(XmlFlattenedTrait.self)
        let mapSchema = targetSchema(schema)
        let keyName = xmlElementName(for: mapSchema.key)
        let valueName = xmlElementName(for: mapSchema.value)
        var map = [String: V]()

        let entries: [Reader]
        if isFlattened {
            let elementName = xmlElementName(for: schema)
            entries = (reader.parent?.children ?? []).filter { $0.nodeInfo.name == elementName }
        } else {
            entries = reader.children.filter { $0.nodeInfo.name == "entry" }
        }

        for entry in entries {
            let keyReader = entry[NodeInfo(keyName)]
            guard let key: String = try keyReader.readIfPresent() else { continue }
            let valueReader = entry[NodeInfo(valueName)]
            let value = try consumer(Deserializer(reader: valueReader))
            map[key] = value
        }
        return map
    }

    public func readBoolean(_ schema: Schema) throws -> Bool {
        guard let value: Bool = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected boolean for \(schema.id)")
        }
        return value
    }

    public func readByte(_ schema: Schema) throws -> Int8 {
        guard let value: Int8 = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected Int8 for \(schema.id)")
        }
        return value
    }

    public func readShort(_ schema: Schema) throws -> Int16 {
        guard let value: Int16 = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected Int16 for \(schema.id)")
        }
        return value
    }

    public func readInteger(_ schema: Schema) throws -> Int {
        guard let value: Int = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected Int for \(schema.id)")
        }
        return value
    }

    public func readLong(_ schema: Schema) throws -> Int {
        guard let value: Int = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected Int (long) for \(schema.id)")
        }
        return value
    }

    public func readFloat(_ schema: Schema) throws -> Float {
        guard let value: Float = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected Float for \(schema.id)")
        }
        return value
    }

    public func readDouble(_ schema: Schema) throws -> Double {
        guard let value: Double = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected Double for \(schema.id)")
        }
        return value
    }

    public func readBigInteger(_ schema: Schema) throws -> Int64 {
        guard let str: String = try reader.readIfPresent(), let value = Int64(str) else {
            throw XMLDeserializerError("Expected Int64 for \(schema.id)")
        }
        return value
    }

    public func readBigDecimal(_ schema: Schema) throws -> Double {
        try readDouble(schema)
    }

    public func readString(_ schema: Schema) throws -> String {
        guard let value: String = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected String for \(schema.id)")
        }
        return value
    }

    public func readBlob(_ schema: Schema) throws -> Data {
        guard let value: Data = try reader.readIfPresent() else {
            throw XMLDeserializerError("Expected blob for \(schema.id)")
        }
        return value
    }

    public func readTimestamp(_ schema: Schema) throws -> Date {
        let format = resolveTimestampFormat(schema)
        guard let value: Date = try reader.readTimestampIfPresent(format: format) else {
            throw XMLDeserializerError("Expected timestamp for \(schema.id)")
        }
        return value
    }

    public func readDocument(_ schema: Schema) throws -> Document {
        throw SerializerError("Document type not supported in XML")
    }

    public func readNull<T>(_ schema: Schema) throws -> T? {
        return nil
    }

    public func isNull() throws -> Bool {
        !reader.hasContent && reader.children.isEmpty
    }

    public var containerSize: Int { reader.children.count }

    private func xmlElementName(for schema: Schema) -> String {
        (try? schema.getTrait(XmlNameTrait.self))?.value ?? schema.memberName ?? schema.id.member ?? schema.id.name
    }
}

struct XMLDeserializerError: Error {
    let localizedDescription: String
    init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}

struct DecodedNull: Error {}
