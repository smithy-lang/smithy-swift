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
import protocol SmithySerialization.SerializableStruct
@_spi(SchemaBasedSerde)
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter

/// A `ShapeSerializer` that writes an `application/x-www-form-urlencoded` request body
/// for the `awsQuery` and `ec2Query` protocols.
///
/// Every value is written as a `key=value` pair, with pairs separated by `&`.  The key is
/// the dot-separated path from the top-level input structure down to the value.  Keys and
/// values are percent-encoded, leaving only RFC 3986 unreserved characters unencoded.
///
/// See:
/// - https://smithy.io/2.0/aws/protocols/aws-query-protocol.html
/// - https://smithy.io/2.0/aws/protocols/aws-ec2-query-protocol.html
@_spi(SchemaBasedSerde)
public final class Serializer: ShapeSerializer {

    /// The protocol whose serialization rules are followed.
    public enum Variant: Sendable {
        /// `aws.protocols#awsQuery`
        case awsQuery
        /// `aws.protocols#ec2Query`
        case ec2Query
    }

    // ASCII (and UTF-8) values for significant characters in form URL encoding
    private static let ampersand: UInt8 = 38
    private static let dot: UInt8 = 46
    private static let equals: UInt8 = 61
    private static let percent: UInt8 = 37
    private static let hexDigits: [UInt8] = Array("0123456789ABCDEF".utf8)

    // ASCII (and UTF-8) sequences for tokens used in form URL encoding
    private static let trueBytes = Array("true".utf8)
    private static let falseBytes = Array("false".utf8)
    private static let nan = Array("NaN".utf8)
    private static let positiveInfinity = Array("Infinity".utf8)
    private static let negativeInfinity = Array("-Infinity".utf8)
    private static let entryBytes = Array("entry".utf8)
    private static let keyBytes = Array("key".utf8)
    private static let valueBytes = Array("value".utf8)

    /// The protocol whose serialization rules are followed.
    public let variant: Variant

    private var _data: [UInt8]

    /// The key for the structure currently being written, with a trailing dot, or empty for the top-level structure.
    private var prefix: [UInt8] = []

    /// The complete key for the list element or map value that is about to be written.
    private var elementKey: [UInt8] = []

    /// Creates a new form URL serializer.
    ///
    /// The `Action` & `Version` params are not part of the input structure, so the client protocol
    /// should supply them here.  When supplied, they are written before any other params.
    /// - Parameters:
    ///   - variant: The protocol whose serialization rules are to be followed.
    ///   - action: The value for the `Action` param, typically the operation name.  Omitted if `nil`.
    ///   - version: The value for the `Version` param, typically the service API version.  Omitted if `nil`.
    public init(variant: Variant, action: String? = nil, version: String? = nil) {
        self.variant = variant
        self._data = [UInt8]()
        self._data.reserveCapacity(4096)
        if let action {
            appendPair(key: Array("Action".utf8), value: action)
        }
        if let version {
            appendPair(key: Array("Version".utf8), value: version)
        }
    }

    // MARK: - Aggregate shapes

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        // The top-level structure has no key; members of a nested structure are prefixed with its key.
        let savedPrefix = prefix
        if schema.containerType != nil {
            prefix = try key(for: schema)
            prefix.append(Self.dot)
        }
        try value.serializeMembers(schema, self)
        prefix = savedPrefix
    }

    public func writeList<E>(
        _ schema: Schema,
        _ value: [E],
        _ consumer: (E, any ShapeSerializer) throws -> Void
    ) throws {
        let key = try key(for: schema)

        // An empty list is written as a key with an empty value in awsQuery, and is omitted in ec2Query.
        guard !value.isEmpty else {
            if variant == .awsQuery { appendPair(key: key, valueBytes: []) }
            return
        }

        // Lists are always flattened in ec2Query.  In awsQuery, a non-flattened list's elements are
        // nested under the list member's name, i.e. `ListArg.member.1`.
        var base = key
        if variant == .awsQuery && !schema.hasTrait(XMLFlattenedTrait.self) {
            base.append(Self.dot)
            base.append(contentsOf: try schema.member.getOrCreateExtension(AWSQueryNameExtension.self).name)
        }

        // Write each element with a key ending in its 1-based index.
        let savedElementKey = elementKey
        for (index, element) in value.enumerated() {
            elementKey = base
            elementKey.append(Self.dot)
            elementKey.append(contentsOf: String(index + 1).utf8)
            try consumer(element, self)
        }
        elementKey = savedElementKey
    }

    public func writeMap<V>(
        _ schema: Schema,
        _ value: [String: V],
        _ consumer: (V, any ShapeSerializer) throws -> Void
    ) throws {
        // An empty map is omitted.
        guard !value.isEmpty else { return }
        let key = try key(for: schema)

        // A non-flattened map's entries are nested under `entry`, i.e. `MapArg.entry.1.key`.
        var base = key
        if !schema.hasTrait(XMLFlattenedTrait.self) {
            base.append(Self.dot)
            base.append(contentsOf: Self.entryBytes)
        }
        let keyName = try schema.key.getOrCreateExtension(AWSQueryNameExtension.self).name
        let valueName = try schema.value.getOrCreateExtension(AWSQueryNameExtension.self).name

        // Entries are written in key order so that the output is deterministic.
        let savedElementKey = elementKey
        for (index, (mapKey, mapValue)) in value.sorted(by: { $0.key < $1.key }).enumerated() {
            var entryKey = base
            entryKey.append(Self.dot)
            entryKey.append(contentsOf: String(index + 1).utf8)
            entryKey.append(Self.dot)

            // Write the map key, then the map value
            appendPair(key: entryKey + keyName, value: mapKey)
            elementKey = entryKey + valueName
            try consumer(mapValue, self)
        }
        elementKey = savedElementKey
    }

    // MARK: - Simple shapes

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        try appendPair(schema, valueBytes: value ? Self.trueBytes : Self.falseBytes)
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        try appendPair(schema, value: String(value))
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        try appendPair(schema, value: String(value))
    }

    public func writeInteger(_ schema: Schema, _ value: Int32) throws {
        try appendPair(schema, value: String(value))
    }

    public func writeLong(_ schema: Schema, _ value: Int64) throws {
        try appendPair(schema, value: String(value))
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        try writeFloatingPoint(schema, value)
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        try writeFloatingPoint(schema, value)
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        try appendPair(schema, value: String(value))
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        try writeFloatingPoint(schema, value)
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        try appendPair(schema, value: value)
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        try appendPair(schema, value: value.base64EncodedString())
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        // awsQuery & ec2Query default to date-time when no timestampFormat trait is present.
        let format = schema.getTrait(TimestampFormatTrait.self)?.format ?? .dateTime
        try appendPair(schema, value: TimestampFormatter(format: format).string(from: value))
    }

    public func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws {
        throw SerializerError("Documents are not supported by the awsQuery or ec2Query protocols")
    }

    public func writeNull(_ schema: Schema) throws {
        // Null has no representation in form URL encoding, so nothing is written.
    }

    public var data: Data? {
        get throws {
            !_data.isEmpty ? Data(_data) : nil
        }
    }

    public var mediaType: String? { !_data.isEmpty ? "application/x-www-form-urlencoded" : nil }

    // MARK: - Private methods

    private func writeFloatingPoint<FP: FloatingPoint & LosslessStringConvertible>(
        _ schema: Schema,
        _ value: FP
    ) throws {
        if value.isNaN {
            try appendPair(schema, valueBytes: Self.nan)
        } else if value == .infinity {
            try appendPair(schema, valueBytes: Self.positiveInfinity)
        } else if value == -.infinity {
            try appendPair(schema, valueBytes: Self.negativeInfinity)
        } else {
            try appendPair(schema, value: value.description)
        }
    }

    /// Returns the complete, percent-encoded key for the value described by the passed schema.
    private func key(for schema: Schema) throws -> [UInt8] {
        switch schema.containerType {
        case .structure, .union:
            return prefix + (try memberName(schema))
        case .list, .map:
            return elementKey
        default:
            throw SerializerError("Only structures may be serialized at top level, not \(schema.type)")
        }
    }

    /// Returns the percent-encoded name for a structure or union member.
    private func memberName(_ schema: Schema) throws -> [UInt8] {
        switch variant {
        case .awsQuery:
            return try schema.getOrCreateExtension(AWSQueryNameExtension.self).name
        case .ec2Query:
            return try schema.getOrCreateExtension(EC2QueryNameExtension.self).name
        }
    }

    /// Writes a pair for the value described by the passed schema.  The value is percent-encoded.
    private func appendPair(_ schema: Schema, value: String) throws {
        try appendKey(schema)
        Self.appendPercentEncoded(value, to: &_data)
    }

    /// Writes a pair for the value described by the passed schema.  The value bytes must not require percent-encoding.
    private func appendPair(_ schema: Schema, valueBytes: [UInt8]) throws {
        try appendKey(schema)
        _data.append(contentsOf: valueBytes)
    }

    /// Writes a pair using a key that has already been percent-encoded.  The value is percent-encoded.
    private func appendPair(key: [UInt8], value: String) {
        appendSeparatorIfNeeded()
        _data.append(contentsOf: key)
        _data.append(Self.equals)
        Self.appendPercentEncoded(value, to: &_data)
    }

    /// Writes a pair using a key that has already been percent-encoded.  The value bytes must not require percent-encoding.
    private func appendPair(key: [UInt8], valueBytes: [UInt8]) {
        appendSeparatorIfNeeded()
        _data.append(contentsOf: key)
        _data.append(Self.equals)
        _data.append(contentsOf: valueBytes)
    }

    /// Writes the separator, key, and `=` for the value described by the passed schema.
    ///
    /// Writes the key directly into the output to avoid allocating a key array for every value.
    private func appendKey(_ schema: Schema) throws {
        appendSeparatorIfNeeded()
        switch schema.containerType {
        case .structure, .union:
            _data.append(contentsOf: prefix)
            _data.append(contentsOf: try memberName(schema))
        case .list, .map:
            _data.append(contentsOf: elementKey)
        default:
            throw SerializerError("Only structures may be serialized at top level, not \(schema.type)")
        }
        _data.append(Self.equals)
    }

    private func appendSeparatorIfNeeded() {
        if !_data.isEmpty { _data.append(Self.ampersand) }
    }

    /// Percent-encodes the passed string's UTF-8 bytes and appends them to the passed buffer.
    ///
    /// RFC 3986 unreserved characters (`A-Z`, `a-z`, `0-9`, `-`, `.`, `_`, `~`) are written as-is;
    /// all other bytes are written as `%XX` using uppercase hex digits.
    static func appendPercentEncoded(_ string: String, to buffer: inout [UInt8]) {
        for byte in string.utf8 {
            switch byte {
            case UInt8(ascii: "A")...UInt8(ascii: "Z"),
                 UInt8(ascii: "a")...UInt8(ascii: "z"),
                 UInt8(ascii: "0")...UInt8(ascii: "9"),
                 UInt8(ascii: "-"), UInt8(ascii: "."), UInt8(ascii: "_"), UInt8(ascii: "~"):
                buffer.append(byte)
            default:
                buffer.append(percent)
                buffer.append(hexDigits[Int(byte >> 4)])
                buffer.append(hexDigits[Int(byte & 0x0F)])
            }
        }
    }

    /// Returns the percent-encoded UTF-8 bytes for the passed string.
    static func percentEncoded(_ string: String) -> [UInt8] {
        var buffer = [UInt8]()
        appendPercentEncoded(string, to: &buffer)
        return buffer
    }
}
