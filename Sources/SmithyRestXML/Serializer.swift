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
import struct Smithy.TimestampFormatTrait
import struct Smithy.XmlAttributeTrait
import struct Smithy.XmlFlattenedTrait
import struct Smithy.XmlNameTrait
import struct Smithy.XmlNamespaceTrait
import protocol Smithy.SmithyDocument
import protocol SmithySerialization.SerializableStruct
import struct SmithySerialization.SerializerError
import protocol SmithySerialization.ShapeSerializer
import typealias SmithySerialization.WriteValueConsumer
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter
@_spi(SmithyTimestamps) import enum SmithyTimestamps.TimestampFormat

public final class Serializer: ShapeSerializer {
    private var xmlParts: [String] = []

    public init() {}

    // MARK: - ShapeSerializer

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        let elementName = xmlElementName(for: schema)
        let nsAttr = xmlNamespaceAttr(for: schema)
        xmlParts.append("<\(elementName)\(nsAttr)>")
        for member in schema.members {
            try S.writeConsumer(member, value, self)
        }
        xmlParts.append("</\(elementName)>")
    }

    public func writeList<E>(_ schema: Schema, _ value: [E], _ consumer: WriteValueConsumer<E>) throws {
        let isFlattened = schema.hasTrait(XmlFlattenedTrait.self)
        if isFlattened {
            let elementName = xmlElementName(for: schema)
            for element in value {
                xmlParts.append("<\(elementName)>")
                try consumer(element, self)
                xmlParts.append("</\(elementName)>")
            }
        } else {
            writeMemberOpen(schema: schema)
            let memberSchema = (schema.target ?? schema).member
            let memberName = xmlElementName(for: memberSchema)
            for element in value {
                xmlParts.append("<\(memberName)>")
                try consumer(element, self)
                xmlParts.append("</\(memberName)>")
            }
            writeMemberClose(schema: schema)
        }
    }

    public func writeMap<V>(_ schema: Schema, _ value: [String: V], _ consumer: WriteValueConsumer<V>) throws {
        let isFlattened = schema.hasTrait(XmlFlattenedTrait.self)
        let mapSchema = schema.target ?? schema
        let keyName = xmlElementName(for: mapSchema.key)
        let valueName = xmlElementName(for: mapSchema.value)
        if isFlattened {
            let elementName = xmlElementName(for: schema)
            for (k, v) in value {
                xmlParts.append("<\(elementName)>")
                xmlParts.append("<\(keyName)>\(xmlEscape(k))</\(keyName)>")
                xmlParts.append("<\(valueName)>")
                try consumer(v, self)
                xmlParts.append("</\(valueName)>")
                xmlParts.append("</\(elementName)>")
            }
        } else {
            writeMemberOpen(schema: schema)
            for (k, v) in value {
                xmlParts.append("<entry>")
                xmlParts.append("<\(keyName)>\(xmlEscape(k))</\(keyName)>")
                xmlParts.append("<\(valueName)>")
                try consumer(v, self)
                xmlParts.append("</\(valueName)>")
                xmlParts.append("</entry>")
            }
            writeMemberClose(schema: schema)
        }
    }

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        writeScalar(schema: schema, string: value ? "true" : "false")
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        writeScalar(schema: schema, string: "\(value)")
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        writeScalar(schema: schema, string: "\(value)")
    }

    public func writeInteger(_ schema: Schema, _ value: Int) throws {
        writeScalar(schema: schema, string: "\(value)")
    }

    public func writeLong(_ schema: Schema, _ value: Int) throws {
        writeScalar(schema: schema, string: "\(value)")
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        if value.isNaN { writeScalar(schema: schema, string: "NaN") }
        else if value == .infinity { writeScalar(schema: schema, string: "Infinity") }
        else if value == -.infinity { writeScalar(schema: schema, string: "-Infinity") }
        else { writeScalar(schema: schema, string: "\(value)") }
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        if value.isNaN { writeScalar(schema: schema, string: "NaN") }
        else if value == .infinity { writeScalar(schema: schema, string: "Infinity") }
        else if value == -.infinity { writeScalar(schema: schema, string: "-Infinity") }
        else { writeScalar(schema: schema, string: "\(value)") }
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        writeScalar(schema: schema, string: "\(value)")
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        try writeDouble(schema, value)
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        writeScalar(schema: schema, string: xmlEscape(value))
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        writeScalar(schema: schema, string: value.base64EncodedString())
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        let tsFormat = resolveTimestampFormat(schema)
        let formatted = TimestampFormatter(format: tsFormat).string(from: value)
        writeScalar(schema: schema, string: formatted)
    }

    public func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws {
        throw SerializerError("Document type not supported in XML")
    }

    public func writeNull(_ schema: Schema) throws {
        // Null not defined in XML. No operation.
    }

    public var data: Data {
        Data(xmlParts.joined().utf8)
    }

    // MARK: - Private

    private func xmlElementName(for schema: Schema) -> String {
        (try? schema.getTrait(XmlNameTrait.self))?.value ?? schema.memberName ?? schema.id.member ?? schema.id.name
    }

    private func xmlNamespaceAttr(for schema: Schema) -> String {
        guard let ns = try? schema.getTrait(XmlNamespaceTrait.self) else { return "" }
        if let prefix = ns.prefix, !prefix.isEmpty {
            return " xmlns:\(prefix)=\"\(ns.uri)\""
        }
        return " xmlns=\"\(ns.uri)\""
    }

    private func writeScalar(schema: Schema, string: String) {
        if schema.hasTrait(XmlAttributeTrait.self) {
            // Attributes are handled during struct writing; this is a fallback
            writeMemberOpen(schema: schema)
            xmlParts.append(string)
            writeMemberClose(schema: schema)
        } else {
            writeMemberOpen(schema: schema)
            xmlParts.append(string)
            writeMemberClose(schema: schema)
        }
    }

    private func writeMemberOpen(schema: Schema) {
        guard let name = schema.memberName else { return }
        let elementName = (try? schema.getTrait(XmlNameTrait.self))?.value ?? name
        let nsAttr = xmlNamespaceAttr(for: schema)
        xmlParts.append("<\(elementName)\(nsAttr)>")
    }

    private func writeMemberClose(schema: Schema) {
        guard let name = schema.memberName else { return }
        let elementName = (try? schema.getTrait(XmlNameTrait.self))?.value ?? name
        xmlParts.append("</\(elementName)>")
    }

    private func xmlEscape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
