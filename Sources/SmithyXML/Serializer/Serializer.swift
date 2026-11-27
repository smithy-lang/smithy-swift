//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
@_spi(SchemaBasedSerde)
import class Smithy.Schema
import protocol Smithy.SmithyDocument
@_spi(SchemaBasedSerde)
import class Smithy.TimestampFormatTrait
@_spi(SchemaBasedSerde)
import class Smithy.XMLFlattenedTrait
@_spi(SchemaBasedSerde)
import class Smithy.XMLNamespaceTrait
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct
@_spi(SchemaBasedSerde)
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter

/// A shape serializer that writes XML for the Smithy `restXml` protocol.
///
/// Values are written per Smithy's XML binding rules (https://smithy.io/2.0/spec/protocol-traits.html#xml-bindings):
/// - The shape written first is the root element, named by the `xmlName` of the member being written (for an
///   HTTP payload), else the `xmlName` of the shape, else the shape's name.  Its namespace is the member's or the
///   shape's `xmlNamespace`, else the default namespace passed at init, typically the service's.
/// - A structure or union member is an element named by the member's `xmlName`, else the member name, with a
///   namespace declaration if the member has `xmlNamespace`.  Members with `xmlAttribute` are written as
///   attributes of the enclosing structure's element instead.
/// - A list is a wrapper element with one child element per item, named by the `xmlName` of the list's member,
///   else `member`.  A flattened list (`xmlFlattened`) has no wrapper: each item is an element named for the
///   structure member.
/// - A map is a wrapper element with one `entry` element per entry, each containing a key element and a value
///   element, named by the `xmlName` of the map's key & value members, else `key` & `value`.  A flattened map has
///   no wrapper: each entry is an element named for the structure member.  Entries are written in key order.
/// - Timestamps are `date-time` unless the `timestampFormat` trait says otherwise, and blobs are base64-encoded.
///   Floats use `NaN`, `Infinity` & `-Infinity` for non-finite values.  Nulls are omitted, and documents throw.
///
/// XML is written as UTF-8 bytes directly into a buffer, with no XML declaration.
@_spi(SchemaBasedSerde)
public final class Serializer: ShapeSerializer {

    // ASCII (and UTF-8) values for significant characters in XML
    private static let lessThan = UInt8(ascii: "<")
    private static let greaterThan = UInt8(ascii: ">")
    private static let slash = UInt8(ascii: "/")
    private static let space = UInt8(ascii: " ")
    private static let equals = UInt8(ascii: "=")
    private static let doubleQuote = UInt8(ascii: "\"")

    // ASCII (and UTF-8) sequences for tokens used in XML
    private static let trueBytes = Array("true".utf8)
    private static let falseBytes = Array("false".utf8)
    private static let nan = Array("NaN".utf8)
    private static let positiveInfinity = Array("Infinity".utf8)
    private static let negativeInfinity = Array("-Infinity".utf8)
    private static let entryName = Array("entry".utf8)

    /// The namespace declaration applied to the root element when it has no `xmlNamespace` of its own.
    private let defaultNamespace: [UInt8]

    private var _data: [UInt8]

    /// The number of elements that have been started and not yet ended.  Zero when writing the root element.
    private var depth = 0

    /// The element name & namespace declaration for the list item or map value about to be written.
    private var itemName: [UInt8] = []
    private var itemNamespace: [UInt8] = []

    /// `true` while a structure's attribute members are being written into its start tag.
    private var isWritingAttributes = false

    /// Creates a new XML serializer.
    /// - Parameter defaultNamespace: The namespace for the root element if it has no `xmlNamespace` of its own.
    ///   For `restXml`, this is the service's `xmlNamespace`, if it has one.
    public init(defaultNamespace: XMLNamespaceTrait? = nil) {
        self.defaultNamespace = Self.namespaceDeclaration(defaultNamespace)
        self._data = [UInt8]()
        self._data.reserveCapacity(4096)
    }

    // MARK: - Aggregate shapes

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        // Structures are never attributes, so nothing is written while writing attributes.
        guard !isWritingAttributes, try !isAttributeMember(schema) else { return }

        let name = try writeStartTag(schema)
        depth += 1

        // Attributes must be in the start tag, before any content.  If the structure has attribute members,
        // they are written in a pass of their own, during which all other members are skipped.
        let structure = schema.containerType != nil ? (schema.target ?? schema) : schema
        if try structure.getOrCreateExtension(XMLAttributeMembersExtension.self).hasAttributeMembers {
            isWritingAttributes = true
            defer { isWritingAttributes = false }
            try value.serializeMembers(schema, self)
        }
        _data.append(Self.greaterThan)

        try value.serializeMembers(schema, self)

        writeEndTag(name)
        depth -= 1
    }

    public func writeList<E>(
        _ schema: Schema,
        _ value: [E],
        _ consumer: (E, any ShapeSerializer) throws -> Void
    ) throws {
        guard !isWritingAttributes, try !isAttributeMember(schema) else { return }
        let listMember = try schema.member.getOrCreateExtension(XMLNameExtension.self)

        let savedItemName = itemName
        let savedItemNamespace = itemNamespace
        defer {
            itemName = savedItemName
            itemNamespace = savedItemNamespace
        }

        if try isFlattened(schema) {
            // Each item is an element named for the structure member, with no wrapper.
            let structureMember = try schema.getOrCreateExtension(XMLNameExtension.self)
            itemName = structureMember.name
            itemNamespace = structureMember.namespace.isEmpty ? listMember.namespace : structureMember.namespace
            for element in value {
                try consumer(element, self)
            }
        } else {
            // Items are elements named for the list's member, inside a wrapper element.
            let name = try writeStartTag(schema)
            _data.append(Self.greaterThan)
            depth += 1
            itemName = listMember.name
            itemNamespace = listMember.namespace
            for element in value {
                try consumer(element, self)
            }
            writeEndTag(name)
            depth -= 1
        }
    }

    public func writeMap<V>(
        _ schema: Schema,
        _ value: [String: V],
        _ consumer: (V, any ShapeSerializer) throws -> Void
    ) throws {
        guard !isWritingAttributes, try !isAttributeMember(schema) else { return }
        let mapKey = try schema.key.getOrCreateExtension(XMLNameExtension.self)
        let mapValue = try schema.value.getOrCreateExtension(XMLNameExtension.self)

        let savedItemName = itemName
        let savedItemNamespace = itemNamespace
        defer {
            itemName = savedItemName
            itemNamespace = savedItemNamespace
        }

        // A flattened map has an element named for the structure member for each entry, with no wrapper.
        // Otherwise, there is an `entry` element for each entry, inside a wrapper element.
        let isFlattened = try isFlattened(schema)
        let entryName: [UInt8]
        let entryNamespace: [UInt8]
        var wrapperName: [UInt8]?
        if isFlattened {
            let structureMember = try schema.getOrCreateExtension(XMLNameExtension.self)
            entryName = structureMember.name
            entryNamespace = structureMember.namespace
        } else {
            wrapperName = try writeStartTag(schema)
            _data.append(Self.greaterThan)
            entryName = Self.entryName
            entryNamespace = []
        }
        depth += 1

        // Entries are written in key order so that the output is deterministic.
        for (key, element) in value.sorted(by: { $0.key < $1.key }) {
            writeStartTag(name: entryName, namespace: entryNamespace)
            _data.append(Self.greaterThan)

            writeStartTag(name: mapKey.name, namespace: mapKey.namespace)
            _data.append(Self.greaterThan)
            Self.appendEscaped(key, isAttribute: false, to: &_data)
            writeEndTag(mapKey.name)

            itemName = mapValue.name
            itemNamespace = mapValue.namespace
            try consumer(element, self)

            writeEndTag(entryName)
        }

        depth -= 1
        if let wrapperName { writeEndTag(wrapperName) }
    }

    // MARK: - Simple shapes

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        try writeValue(schema, bytes: value ? Self.trueBytes : Self.falseBytes)
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        try writeValue(schema, bytes: Array(String(value).utf8))
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        try writeValue(schema, bytes: Array(String(value).utf8))
    }

    public func writeInteger(_ schema: Schema, _ value: Int32) throws {
        try writeValue(schema, bytes: Array(String(value).utf8))
    }

    public func writeLong(_ schema: Schema, _ value: Int64) throws {
        try writeValue(schema, bytes: Array(String(value).utf8))
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        try writeFloatingPoint(schema, value)
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        try writeFloatingPoint(schema, value)
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        try writeValue(schema, bytes: Array(String(value).utf8))
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        try writeFloatingPoint(schema, value)
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        try writeValue(schema, string: value)
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        // Base64 contains no characters that require escaping in XML.
        try writeValue(schema, bytes: Array(value.base64EncodedData()))
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        // restXml defaults to date-time when no timestampFormat trait is present.
        let format = schema.getTrait(TimestampFormatTrait.self)?.format ?? .dateTime
        try writeValue(schema, string: TimestampFormatter(format: format).string(from: value))
    }

    public func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws {
        throw SerializerError("Documents are not supported by the restXml protocol")
    }

    public func writeNull(_ schema: Schema) throws {
        // Null has no representation in XML, so nothing is written.
    }

    public var data: Data? {
        get throws {
            !_data.isEmpty ? Data(_data) : nil
        }
    }

    public var mediaType: String? { !_data.isEmpty ? "application/xml" : nil }

    // MARK: - Writing elements

    private func writeFloatingPoint<FP: FloatingPoint & LosslessStringConvertible>(
        _ schema: Schema,
        _ value: FP
    ) throws {
        if value.isNaN {
            try writeValue(schema, bytes: Self.nan)
        } else if value == .infinity {
            try writeValue(schema, bytes: Self.positiveInfinity)
        } else if value == -.infinity {
            try writeValue(schema, bytes: Self.negativeInfinity)
        } else {
            try writeValue(schema, bytes: Array(value.description.utf8))
        }
    }

    /// Writes a simple value, which must be escaped, as an element or attribute.
    private func writeValue(_ schema: Schema, string: String) throws {
        try writeValue(schema) { isAttribute in
            Self.appendEscaped(string, isAttribute: isAttribute, to: &_data)
        }
    }

    /// Writes a simple value, whose bytes require no escaping, as an element or attribute.
    private func writeValue(_ schema: Schema, bytes: [UInt8]) throws {
        try writeValue(schema) { _ in _data.append(contentsOf: bytes) }
    }

    /// Writes a simple value as an attribute when writing attributes, else as an element.
    ///
    /// `writeContent` writes the value, escaped for an attribute if its parameter is `true`.
    private func writeValue(_ schema: Schema, _ writeContent: (Bool) -> Void) throws {
        if isWritingAttributes {
            // Only attribute members of the structure are written while writing attributes.
            guard try isAttributeMember(schema) else { return }
            let member = try schema.getOrCreateExtension(XMLNameExtension.self)
            _data.append(Self.space)
            _data.append(contentsOf: member.name)
            _data.append(Self.equals)
            _data.append(Self.doubleQuote)
            writeContent(true)
            _data.append(Self.doubleQuote)
        } else {
            // Attribute members were already written to the structure's start tag.
            guard try !isAttributeMember(schema) else { return }
            let name = try writeStartTag(schema)
            _data.append(Self.greaterThan)
            writeContent(false)
            writeEndTag(name)
        }
    }

    /// Writes the start tag for the element for the passed schema, without the closing `>`, so that
    /// attributes may follow.  Returns the element's name.
    private func writeStartTag(_ schema: Schema) throws -> [UInt8] {
        let name: [UInt8]
        let namespace: [UInt8]
        if depth == 0 {
            let root = try schema.getOrCreateExtension(XMLRootNameExtension.self)
            name = root.name
            namespace = root.namespace ?? defaultNamespace
        } else {
            switch schema.containerType {
            case .structure, .union:
                let member = try schema.getOrCreateExtension(XMLNameExtension.self)
                name = member.name
                namespace = member.namespace
            case .list, .set, .map:
                name = itemName
                namespace = itemNamespace
            default:
                throw SerializerError("\(schema.id) cannot be written as an XML element")
            }
        }
        writeStartTag(name: name, namespace: namespace)
        return name
    }

    private func writeStartTag(name: [UInt8], namespace: [UInt8]) {
        _data.append(Self.lessThan)
        _data.append(contentsOf: name)
        _data.append(contentsOf: namespace)
    }

    private func writeEndTag(_ name: [UInt8]) {
        _data.append(Self.lessThan)
        _data.append(Self.slash)
        _data.append(contentsOf: name)
        _data.append(Self.greaterThan)
    }

    /// `true` if the passed schema is a structure or union member written as an attribute.
    private func isAttributeMember(_ schema: Schema) throws -> Bool {
        guard depth > 0, schema.containerType == .structure || schema.containerType == .union else { return false }
        return try schema.getOrCreateExtension(XMLNameExtension.self).isAttribute
    }

    /// `true` if the passed schema is a flattened list or map member of a structure or union.
    private func isFlattened(_ schema: Schema) throws -> Bool {
        depth > 0 && (schema.containerType == .structure || schema.containerType == .union)
            && schema.hasTrait(XMLFlattenedTrait.self)
    }

    // MARK: - Escaping

    /// Returns the namespace declaration for the passed `xmlNamespace`, with a leading space,
    /// i.e. ` xmlns:prefix="uri"`, or empty if there is none.
    static func namespaceDeclaration(_ namespace: XMLNamespaceTrait?) -> [UInt8] {
        guard let namespace else { return [] }
        var bytes = Array(" xmlns".utf8)
        if let prefix = namespace.prefix {
            bytes.append(UInt8(ascii: ":"))
            appendEscaped(prefix, isAttribute: true, to: &bytes)
        }
        bytes.append(contentsOf: "=\"".utf8)
        appendEscaped(namespace.uri, isAttribute: true, to: &bytes)
        bytes.append(doubleQuote)
        return bytes
    }

    /// Returns the passed string as UTF-8 bytes, escaped for XML.
    static func escaped(_ string: String, isAttribute: Bool) -> [UInt8] {
        var bytes = [UInt8]()
        appendEscaped(string, isAttribute: isAttribute, to: &bytes)
        return bytes
    }

    /// Appends the passed string's UTF-8 bytes to the buffer, escaped for XML text or, if `isAttribute`
    /// is `true`, for a double-quoted attribute value.
    ///
    /// `&`, `<` & `>` are always escaped, and carriage returns are written as character references so
    /// that XML line-end normalization doesn't remove them.  In attribute values, `"` is also escaped, and
    /// tabs & line feeds are written as character references so attribute-value normalization doesn't
    /// replace them with spaces.
    static func appendEscaped(_ string: String, isAttribute: Bool, to buffer: inout [UInt8]) {
        let utf8 = string.utf8
        var copyStart = utf8.startIndex
        for index in utf8.indices {
            let replacement: StaticString
            switch utf8[index] {
            case UInt8(ascii: "&"): replacement = "&amp;"
            case UInt8(ascii: "<"): replacement = "&lt;"
            case UInt8(ascii: ">"): replacement = "&gt;"
            case UInt8(ascii: "\r"): replacement = "&#xD;"
            case UInt8(ascii: "\"") where isAttribute: replacement = "&quot;"
            case UInt8(ascii: "\n") where isAttribute: replacement = "&#xA;"
            case UInt8(ascii: "\t") where isAttribute: replacement = "&#x9;"
            default: continue
            }
            buffer.append(contentsOf: utf8[copyStart..<index])
            replacement.withUTF8Buffer { buffer.append(contentsOf: $0) }
            copyStart = utf8.index(after: index)
        }
        buffer.append(contentsOf: utf8[copyStart..<utf8.endIndex])
    }
}
