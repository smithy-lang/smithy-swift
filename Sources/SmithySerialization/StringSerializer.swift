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

    public func writeStruct(_ schema: Smithy.Schema, _ value: any SerializableStruct) throws {
        try addNameAndValue(schema) {
            let typeName = type(of: value)
            let serializer = StringSerializer(includeMemberNames: true)
            try value.serializeMembers(serializer)
            return "\(typeName)(\(serializer.string))"
        }
    }

    public func writeList(_ schema: Smithy.Schema, _ size: Int, _ consumer: Consumer<any ShapeSerializer>) throws {
        try addNameAndValue(schema) {
            let serializer = StringSerializer(includeMemberNames: false)
            try consumer(serializer)
            return "[\(serializer.string)]"
        }
    }

    public func writeMap(_ schema: Smithy.Schema, _ size: Int, _ consumer: Consumer<any MapSerializer>) throws {
        try addNameAndValue(schema) {
            let serializer = StringSerializer(includeMemberNames: false)
            try consumer(serializer)
            return "[\(serializer.string)]"
        }
    }

    public func writeBoolean(_ schema: Smithy.Schema, _ value: Bool) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeByte(_ schema: Smithy.Schema, _ value: Int8) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeShort(_ schema: Smithy.Schema, _ value: Int16) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeInteger(_ schema: Smithy.Schema, _ value: Int) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeLong(_ schema: Smithy.Schema, _ value: Int) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeFloat(_ schema: Smithy.Schema, _ value: Float) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeDouble(_ schema: Smithy.Schema, _ value: Double) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeBigInteger(_ schema: Smithy.Schema, _ value: Int64) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeBigDecimal(_ schema: Smithy.Schema, _ value: Double) throws {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeString(_ schema: Smithy.Schema, _ value: String) throws {
        addNameAndValue(schema) { "\"\(value)\"" }
    }

    public func writeBlob(_ schema: Smithy.Schema, _ value: Data) throws {
        addNameAndValue(schema) { "<\(value.count) bytes>" }
    }

    public func writeTimestamp(_ schema: Smithy.Schema, _ value: Date) throws {
        let df = ISO8601DateFormatter()
        addNameAndValue(schema) { df.string(from: value) }
    }

    public func writeDocument(_ schema: Smithy.Schema, _ value: any Smithy.SmithyDocument) throws {
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
            try writeList(schema, list.count) { serializer in
                for document in list {
                    try writeDocument(schema.members[0], document)
                }
            }
        case .map:
            let map = try value.asStringMap()
            try writeMap(schema, map.count) { mapSerializer in
                for (key, document) in map {
                    try mapSerializer.writeEntry(schema.members[0], key) { serializer in
                        try serializer.writeDocument(schema.members[1], document)
                    }
                }
            }
        case .document, .enum, .intEnum, .structure, .union, .member, .service, .resource, .operation:
            throw SerializerError("Unsupported or invalid document type: \(value.type)")
        }
    }

    public func writeNull(_ schema: Smithy.Schema) throws {
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

    public func writeEntry(_ keySchema: Smithy.Schema, _ key: String, _ valueConsumer: Consumer<any ShapeSerializer>) throws {
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
