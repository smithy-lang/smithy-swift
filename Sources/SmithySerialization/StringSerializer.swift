//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import class Foundation.ISO8601DateFormatter
import class Smithy.Schema
import struct Smithy.ShapeID
import protocol Smithy.SmithyDocument

public class StringSerializer: ShapeSerializer {
    public private(set) var string = ""
    private var isFirstElement = true
    private var includeMemberNames: Bool
    private let interstitial = ", "
    private let redacted = "[REDACTED]"

    public init() {
        self.includeMemberNames = false
    }

    private init(includeMemberNames: Bool) {
        self.includeMemberNames = includeMemberNames
    }

    public func writeStruct(schema: Smithy.Schema, value: any SerializableStruct) throws {
        try addNameAndValue(schema) {
            let typeName = type(of: value)
            let serializer = StringSerializer(includeMemberNames: true)
            try value.serializeMembers(serializer)
            return "\(typeName)(\(serializer.string))"
        }
    }

    public func writeList(schema: Smithy.Schema, size: Int, consumer: Consumer<any ShapeSerializer>) throws {
        try addNameAndValue(schema) {
            let serializer = StringSerializer(includeMemberNames: false)
            try consumer(serializer)
            return "[\(serializer.string)]"
        }
    }

    public func writeMap(schema: Smithy.Schema, size: Int, consumer: Consumer<any MapSerializer>) throws {
        try addNameAndValue(schema) {
            let serializer = StringSerializer(includeMemberNames: false)
            try consumer(serializer)
            return "[\(serializer.string)]"
        }
    }

    public func writeBoolean(schema: Smithy.Schema, value: Bool) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeByte(schema: Smithy.Schema, value: Int8) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeShort(schema: Smithy.Schema, value: Int16) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeInteger(schema: Smithy.Schema, value: Int) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeLong(schema: Smithy.Schema, value: Int) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeFloat(schema: Smithy.Schema, value: Float) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeDouble(schema: Smithy.Schema, value: Double) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeBigInteger(schema: Smithy.Schema, value: Int64) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeBigDecimal(schema: Smithy.Schema, value: Double) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeString(schema: Smithy.Schema, value: String) throws {
        addNameAndValue(schema) { "\"\(value)\"" }
    }

    public func writeBlob(schema: Smithy.Schema, value: Data) throws {
        addNameAndValue(schema) { "<\(value.count) bytes>" }
    }

    public func writeTimestamp(schema: Smithy.Schema, value: Date) throws {
        let df = ISO8601DateFormatter()
        addNameAndValue(schema) { df.string(from: value) }
    }

    public func writeDocument(schema: Smithy.Schema, value: any Smithy.SmithyDocument) throws {
        switch value.type {
        case .blob:
            try writeBlob(schema: schema, value: value.asBlob())
        case .boolean:
            try writeBoolean(schema: schema, value: value.asBoolean())
        case .string:
            try writeString(schema: schema, value: value.asString())
        case .timestamp:
            try writeTimestamp(schema: schema, value: value.asTimestamp())
        case .byte:
            try writeByte(schema: schema, value: value.asByte())
        case .short:
            try writeShort(schema: schema, value: value.asShort())
        case .integer:
            try writeInteger(schema: schema, value: value.asInteger())
        case .long:
            try writeLong(schema: schema, value: Int(value.asLong()))
        case .float:
            try writeFloat(schema: schema, value: value.asFloat())
        case .double:
            try writeDouble(schema: schema, value: value.asDouble())
        case .bigDecimal:
            try writeBigDecimal(schema: schema, value: value.asBigDecimal())
        case .bigInteger:
            try writeBigInteger(schema: schema, value: value.asBigInteger())
        case .list, .set:
            let list = try value.asList()
            try writeList(schema: schema, size: list.count) { serializer in
                for document in list {
                    try writeDocument(schema: schema.members[0], value: document)
                }
            }
        case .map:
            let map = try value.asStringMap()
            try writeMap(schema: schema, size: map.count) { mapSerializer in
                for (key, document) in map {
                    try mapSerializer.writeEntry(keySchema: schema.members[0], key: key) { serializer in
                        try serializer.writeDocument(schema: schema.members[1], value: document)
                    }
                }
            }
        case .document, .enum, .intEnum, .structure, .union, .member, .service, .resource, .operation:
            throw SerializerError("Unsupported or invalid document type: \(value.type)")
        }
    }

    public func writeNull(schema: Smithy.Schema) throws {
        addNameAndValue(schema) { "nil" }
    }

    private func addNameAndValue(_ schema: Smithy.Schema, _ value: () throws -> String) rethrows {
        if !isFirstElement { string += interstitial }
        isFirstElement = false
        if includeMemberNames, schema.type == .member, let name = schema.id.member {
            string += "\(name): "
        }
        string += schema.isSensitive ? redacted : try value()
    }
}

extension StringSerializer: MapSerializer {

    public func writeEntry(keySchema: Smithy.Schema, key: String, valueConsumer: Consumer<any ShapeSerializer>) throws {
        try addNameAndValue(keySchema) {
            let valueSerializer = StringSerializer(includeMemberNames: false)
            try valueConsumer(valueSerializer)
            return "\"\(key)\": \(valueSerializer.string)"
        }
    }
}

extension Smithy.Schema {

    var isSensitive: Bool {
        let sensitive = ShapeID("smithy.api", "sensitive")
        return traits[sensitive] ?? target?.traits[sensitive] != nil
    }
}
