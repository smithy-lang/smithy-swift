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
    private var _string = ""
    let suffix = ", "
    let redacted = "[REDACTED]"

    public init() {}

    public func writeStruct(schema: Smithy.Schema, value: any SerializableStruct) {
        addNameAndValue(schema) {
            let typeName = type(of: value)
            let serializer = StringSerializer()
            value.serializeMembers(serializer)
            serializer.removeTrailingSuffix()
            return "\(typeName)(\(serializer.string()))"
        }
    }

    public func string() -> String {
        removeTrailingSuffix()
        return _string
    }

    public func writeList(schema: Smithy.Schema, size: Int, consumer: (any ShapeSerializer) throws -> Void) {
        addNameAndValue(schema) { "<list>" }
    }
    
    public func writeMap(schema: Smithy.Schema, size: Int, consumer: (any MapSerializer) throws -> Void) {
        addNameAndValue(schema) { "<map>" }
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
        addNameAndValue(schema) { df.string(from: value) }
    }
    
    public func writeDocument(schema: Smithy.Schema, value: any Smithy.SmithyDocument) {
        addNameAndValue(schema) { "<document>" }
    }
    
    public func writeNull(schema: Smithy.Schema) {
        addNameAndValue(schema) { "nil" }
    }

    private func addNameAndValue(_ schema: Schema, _ value: () -> String) {
        if schema.type == .member, let name = schema.id.member {
            _string += "\(name): "
        }
        _string += schema.isSensitive ? redacted : value()
        _string += suffix
    }

    private func removeTrailingSuffix() {
        if _string.hasSuffix(suffix) { _string.removeLast(suffix.count) }
    }
}

private let df = ISO8601DateFormatter()

extension Smithy.Schema {

    var isSensitive: Bool {
        let sensitive = ShapeID("smithy.api", "sensitive")
        return traits[sensitive] ?? target?.traits[sensitive] != nil
    }
}
