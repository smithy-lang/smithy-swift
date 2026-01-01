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
    private let interstitial = ", "
    private let redacted = "[REDACTED]"
    private let key: String?

    public init() {
        self.key = nil
    }

    private init(key: String) {
        self.key = key
    }

    public func writeStruct<S: SerializableStruct>(_ schema: Smithy.Schema, _ value: S) throws {
        try writeValue(schema) {
            let structSerializer = StringSerializer()
            let structMembers = schema.target?.members ?? schema.members
            for member in structMembers {
                try structSerializer.writeValue(member) {
                    let serializer = StringSerializer(key: member.id.member ?? "")
                    try S.writeConsumer(member, value, serializer)
                    return serializer.string
                }
            }
            let typeName = type(of: value)
            return "\(typeName)(\(structSerializer.string))"
        }
    }

    public func writeList<Element>(_ schema: Smithy.Schema, _ value: [Element], _ consumer: WriteValueConsumer<Element>) throws {
        try writeValue(schema) {
            let listSerializer = StringSerializer()
            let elementSchema = schema.target?.members[0] ?? schema.members[0]
            for element in value {
                try listSerializer.writeValue(elementSchema) {
                    let serializer = StringSerializer()
                    try consumer(element, serializer)
                    return serializer.string
                }
            }
            return "[\(listSerializer.string)]"
        }
    }

    public func writeMap<Value>(_ schema: Smithy.Schema, _ value: [String: Value], _ consumer: WriteValueConsumer<Value>) throws {
        try writeValue(schema) {
            let mapSerializer = StringSerializer()
            let valueSchema = schema.target?.members[1] ?? schema.members[1]
            for (key, value) in value {
                try mapSerializer.writeValue(valueSchema) {
                    let serializer = StringSerializer(key: "\"\(key)\"")
                    try consumer(value, serializer)
                    return serializer.string
                }
            }
            return "[\(mapSerializer.string)]"
        }
    }

    public func writeBoolean(_ schema: Smithy.Schema, _ value: Bool) throws {
        writeValue(schema) { "\(value)" }
    }

    public func writeByte(_ schema: Smithy.Schema, _ value: Int8) throws {
        writeValue(schema) { "\(value)" }
    }

    public func writeShort(_ schema: Smithy.Schema, _ value: Int16) throws {
        writeValue(schema) { "\(value)" }
    }

    public func writeInteger(_ schema: Smithy.Schema, _ value: Int) throws {
        writeValue(schema) { "\(value)" }
    }

    public func writeLong(_ schema: Smithy.Schema, _ value: Int) throws {
        writeValue(schema) { "\(value)" }
    }

    public func writeFloat(_ schema: Smithy.Schema, _ value: Float) throws {
        writeValue(schema) { "\(value)" }
    }

    public func writeDouble(_ schema: Smithy.Schema, _ value: Double) throws {
        writeValue(schema) { "\(value)" }
    }

    public func writeBigInteger(_ schema: Smithy.Schema, _ value: Int64) throws {
        writeValue(schema) { "\(value)" }
    }

    public func writeBigDecimal(_ schema: Smithy.Schema, _ value: Double) throws {
        writeValue(schema) { "\(value)" }
    }

    public func writeString(_ schema: Smithy.Schema, _ value: String) throws {
        writeValue(schema) { "\"\(value)\"" }
    }

    public func writeBlob(_ schema: Smithy.Schema, _ value: Data) throws {
        writeValue(schema) { "<\(value.count) bytes>" }
    }

    public func writeTimestamp(_ schema: Smithy.Schema, _ value: Date) throws {
        let df = ISO8601DateFormatter()
        writeValue(schema) { df.string(from: value) }
    }

    public func writeNull(_ schema: Smithy.Schema) throws {
        writeValue(schema) { "nil" }
    }

    private func writeValue(_ schema: Smithy.Schema, _ value: () throws -> String) rethrows {
        if isFirstElement {
            isFirstElement = false
        } else {
            string.append(interstitial)
        }
        if let key {
            string += "\(key): "
        }
        string += schema.isSensitive ? redacted : try value()
    }

    public var data: Data {
        Data(string.utf8)
    }
}

extension Smithy.Schema {

    var isSensitive: Bool {
        let sensitive = ShapeID("smithy.api", "sensitive")
        return traits[sensitive] ?? target?.traits[sensitive] != nil
    }
}
