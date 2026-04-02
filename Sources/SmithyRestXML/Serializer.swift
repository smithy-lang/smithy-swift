//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import enum Smithy.ByteStream
import struct Smithy.Schema
import protocol Smithy.SmithyDocument
import struct Smithy.TimestampFormatTrait
import struct Smithy.XmlAttributeTrait
import struct Smithy.XmlFlattenedTrait
import struct Smithy.XmlNamespaceTrait
import struct Smithy.XmlNameTrait
import protocol SmithySerialization.SerializableStruct
import struct SmithySerialization.SerializerError
import protocol SmithySerialization.ShapeSerializer
import typealias SmithySerialization.WriteValueConsumer
@_spi(SmithyTimestamps) import enum SmithyTimestamps.TimestampFormat
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter
@_spi(SmithyReadWrite) import struct SmithyXML.NodeInfo
@_spi(SmithyReadWrite) import class SmithyXML.Writer

public final class Serializer: ShapeSerializer {
    private var rootWriter: Writer?

    public init() {}

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        let nodeInfo = xmlNodeInfo(for: schema)
        let writer: Writer
        if let rootWriter {
            writer = rootWriter
        } else {
            writer = Writer(nodeInfo: nodeInfo)
            rootWriter = writer
        }
        let memberSerializer = MemberSerializer(parent: writer)
        for member in schema.members {
            try S.writeConsumer(member, value, memberSerializer)
        }
    }

    public func writeList<E>(_ schema: Schema, _ value: [E], _ consumer: WriteValueConsumer<E>) throws {}
    public func writeMap<V>(_ schema: Schema, _ value: [String: V], _ consumer: WriteValueConsumer<V>) throws {}
    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {}
    public func writeByte(_ schema: Schema, _ value: Int8) throws {}
    public func writeShort(_ schema: Schema, _ value: Int16) throws {}
    public func writeInteger(_ schema: Schema, _ value: Int) throws {}
    public func writeLong(_ schema: Schema, _ value: Int) throws {}
    public func writeFloat(_ schema: Schema, _ value: Float) throws {}
    public func writeDouble(_ schema: Schema, _ value: Double) throws {}
    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {}
    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {}
    public func writeString(_ schema: Schema, _ value: String) throws {}
    public func writeBlob(_ schema: Schema, _ value: Data) throws {}
    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {}
    public func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws {
        throw SerializerError("Document type not supported in XML")
    }
    public func writeNull(_ schema: Schema) throws {}

    public var data: Data {
        get throws {
            guard let rootWriter else { return Data() }
            return try rootWriter.data()
        }
    }
}

/// Writes struct members as child elements of a parent Writer node.
/// This is the workhorse serializer — all member writes flow through here.
private final class MemberSerializer: ShapeSerializer {
    let parent: Writer

    init(parent: Writer) {
        self.parent = parent
    }

    func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        let child = parent[xmlNodeInfo(for: schema)]
        let memberSerializer = MemberSerializer(parent: child)
        for member in schema.members {
            try S.writeConsumer(member, value, memberSerializer)
        }
    }

    func writeList<E>(_ schema: Schema, _ value: [E], _ consumer: WriteValueConsumer<E>) throws {
        let isFlattened = schema.hasTrait(XmlFlattenedTrait.self)
        if isFlattened {
            let nodeInfo = xmlNodeInfo(for: schema)
            for element in value {
                try consumer(element, ValueSerializer(writer: parent[nodeInfo]))
            }
        } else {
            let listWriter = parent[xmlNodeInfo(for: schema)]
            let memberSchema = (schema.target ?? schema).member
            let memberNodeInfo = xmlNodeInfo(for: memberSchema)
            for element in value {
                try consumer(element, ValueSerializer(writer: listWriter[memberNodeInfo]))
            }
        }
    }

    func writeMap<V>(_ schema: Schema, _ value: [String: V], _ consumer: WriteValueConsumer<V>) throws {
        let isFlattened = schema.hasTrait(XmlFlattenedTrait.self)
        let mapSchema = schema.target ?? schema
        let keyNodeInfo = xmlNodeInfo(for: mapSchema.key)
        let valueNodeInfo = xmlNodeInfo(for: mapSchema.value)
        if isFlattened {
            let nodeInfo = xmlNodeInfo(for: schema)
            for (k, v) in value {
                let entry = parent[nodeInfo]
                try entry[keyNodeInfo].write(k)
                try consumer(v, ValueSerializer(writer: entry[valueNodeInfo]))
            }
        } else {
            let mapWriter = parent[xmlNodeInfo(for: schema)]
            for (k, v) in value {
                let entry = mapWriter[NodeInfo("entry")]
                try entry[keyNodeInfo].write(k)
                try consumer(v, ValueSerializer(writer: entry[valueNodeInfo]))
            }
        }
    }

    func writeBoolean(_ schema: Schema, _ value: Bool) throws { try parent[xmlNodeInfo(for: schema)].write(value) }
    func writeByte(_ schema: Schema, _ value: Int8) throws { try parent[xmlNodeInfo(for: schema)].write(value) }
    func writeShort(_ schema: Schema, _ value: Int16) throws { try parent[xmlNodeInfo(for: schema)].write(value) }
    func writeInteger(_ schema: Schema, _ value: Int) throws { try parent[xmlNodeInfo(for: schema)].write(value) }
    func writeLong(_ schema: Schema, _ value: Int) throws { try parent[xmlNodeInfo(for: schema)].write(value) }
    func writeFloat(_ schema: Schema, _ value: Float) throws { try parent[xmlNodeInfo(for: schema)].write(value) }
    func writeDouble(_ schema: Schema, _ value: Double) throws { try parent[xmlNodeInfo(for: schema)].write(value) }
    func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        try parent[xmlNodeInfo(for: schema)].write(String(value))
    }
    func writeBigDecimal(_ schema: Schema, _ value: Double) throws { try parent[xmlNodeInfo(for: schema)].write(value) }
    func writeString(_ schema: Schema, _ value: String) throws { try parent[xmlNodeInfo(for: schema)].write(value) }
    func writeBlob(_ schema: Schema, _ value: Data) throws { try parent[xmlNodeInfo(for: schema)].write(value) }
    func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        try parent[xmlNodeInfo(for: schema)].writeTimestamp(value, format: resolveTimestampFormat(schema))
    }
    func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws {
        throw SerializerError("Document type not supported in XML")
    }
    func writeNull(_ schema: Schema) throws {}
    var data: Data { get throws { Data() } }
}

/// Writes a value directly into a Writer node (used for list/map element consumers).
private struct ValueSerializer: ShapeSerializer {
    let writer: Writer

    func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        let memberSerializer = MemberSerializer(parent: writer)
        for member in schema.members {
            try S.writeConsumer(member, value, memberSerializer)
        }
    }

    func writeList<E>(_ schema: Schema, _ value: [E], _ consumer: WriteValueConsumer<E>) throws {
        let memberSchema = (schema.target ?? schema).member
        let memberNodeInfo = xmlNodeInfo(for: memberSchema)
        for element in value {
            try consumer(element, ValueSerializer(writer: writer[memberNodeInfo]))
        }
    }

    func writeMap<V>(_ schema: Schema, _ value: [String: V], _ consumer: WriteValueConsumer<V>) throws {
        let mapSchema = schema.target ?? schema
        let keyNodeInfo = xmlNodeInfo(for: mapSchema.key)
        let valueNodeInfo = xmlNodeInfo(for: mapSchema.value)
        for (k, v) in value {
            let entry = writer[NodeInfo("entry")]
            try entry[keyNodeInfo].write(k)
            try consumer(v, ValueSerializer(writer: entry[valueNodeInfo]))
        }
    }

    func writeBoolean(_ schema: Schema, _ value: Bool) throws { try writer.write(value) }
    func writeByte(_ schema: Schema, _ value: Int8) throws { try writer.write(value) }
    func writeShort(_ schema: Schema, _ value: Int16) throws { try writer.write(value) }
    func writeInteger(_ schema: Schema, _ value: Int) throws { try writer.write(value) }
    func writeLong(_ schema: Schema, _ value: Int) throws { try writer.write(value) }
    func writeFloat(_ schema: Schema, _ value: Float) throws { try writer.write(value) }
    func writeDouble(_ schema: Schema, _ value: Double) throws { try writer.write(value) }
    func writeBigInteger(_ schema: Schema, _ value: Int64) throws { try writer.write(String(value)) }
    func writeBigDecimal(_ schema: Schema, _ value: Double) throws { try writer.write(value) }
    func writeString(_ schema: Schema, _ value: String) throws { try writer.write(value) }
    func writeBlob(_ schema: Schema, _ value: Data) throws { try writer.write(value) }
    func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        try writer.writeTimestamp(value, format: resolveTimestampFormat(schema))
    }
    func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws {
        throw SerializerError("Document type not supported in XML")
    }
    func writeNull(_ schema: Schema) throws {}
    var data: Data { get throws { Data() } }
}

private func xmlNodeInfo(for schema: Schema) -> NodeInfo {
    let name = (try? schema.getTrait(XmlNameTrait.self))?.value
        ?? schema.memberName ?? schema.id.member ?? schema.id.name
    let location: NodeInfo.Location = schema.hasTrait(XmlAttributeTrait.self) ? .attribute : .element
    let namespaceDef: NodeInfo.Namespace?
    if let ns = try? schema.getTrait(XmlNamespaceTrait.self) {
        namespaceDef = NodeInfo.Namespace(prefix: ns.prefix ?? "", uri: ns.uri)
    } else {
        namespaceDef = nil
    }
    return NodeInfo(name, location: location, namespaceDef: namespaceDef)
}
