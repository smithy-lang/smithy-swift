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
    let interstitial = ", "
    let redacted = "[REDACTED]"

    public init() {
        self.includeMemberNames = false
    }

    private init(includeMemberNames: Bool) {
        self.includeMemberNames = includeMemberNames
    }

    public func writeStruct(schema: Smithy.Schema, value: any SerializableStruct) {
        addNameAndValue(schema) {
            let typeName = type(of: value)
            let serializer = StringSerializer(includeMemberNames: true)
            value.serializeMembers(serializer)
            return "\(typeName)(\(serializer.string))"
        }
    }

    public func writeList(schema: Smithy.Schema, size: Int, consumer: (any ShapeSerializer) -> Void) {
        addNameAndValue(schema) {
            let serializer = StringSerializer(includeMemberNames: false)
            consumer(serializer)
            return "[\(serializer.string)]"
        }
    }

    public func writeMap(schema: Smithy.Schema, size: Int, consumer: (any MapSerializer) -> Void) {
        addNameAndValue(schema) {
            let serializer = StringSerializer(includeMemberNames: false)
            consumer(serializer)
            return "[\(serializer.string)]"
        }
    }

    public func writeBoolean(schema: Smithy.Schema, value: Bool) {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeByte(schema: Smithy.Schema, value: Int8) {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeShort(schema: Smithy.Schema, value: Int16) {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeInteger(schema: Smithy.Schema, value: Int) {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeLong(schema: Smithy.Schema, value: Int) {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeFloat(schema: Smithy.Schema, value: Float) {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeDouble(schema: Smithy.Schema, value: Double) {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeBigInteger(schema: Smithy.Schema, value: Int64) {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeBigDecimal(schema: Smithy.Schema, value: Double) {
        addNameAndValue(schema) { "\(value)" }
    }

    public func writeString(schema: Smithy.Schema, value: String) {
        addNameAndValue(schema) { "\"\(value)\"" }
    }

    public func writeBlob(schema: Smithy.Schema, value: Data) {
        addNameAndValue(schema) { "<\(value.count) bytes>" }
    }

    public func writeTimestamp(schema: Smithy.Schema, value: Date) {
        let df = ISO8601DateFormatter()
        addNameAndValue(schema) { df.string(from: value) }
    }

    public func writeDocument(schema: Smithy.Schema, value: any Smithy.SmithyDocument) {
        addNameAndValue(schema) { "<document>" }
    }

    public func writeNull(schema: Smithy.Schema) {
        addNameAndValue(schema) { "nil" }
    }

    private func addNameAndValue(_ schema: Schema, _ value: () -> String) {
        if !isFirstElement { string += interstitial }
        isFirstElement = false
        if includeMemberNames, schema.type == .member, let name = schema.id.member {
            string += "\(name): "
        }
        string += schema.isSensitive ? redacted : value()
    }
}

extension StringSerializer: MapSerializer {

    public func writeEntry(keySchema: Smithy.Schema, key: String, valueConsumer: (any ShapeSerializer) -> Void) {
        addNameAndValue(keySchema) {
            let valueSerializer = StringSerializer(includeMemberNames: false)
            valueConsumer(valueSerializer)
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
