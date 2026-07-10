//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
@_spi(SchemaBasedSerde)
import class Smithy.JSONNameTrait
@_spi(SchemaBasedSerde)
import enum Smithy.Prelude
@_spi(SchemaBasedSerde)
import class Smithy.Schema
import enum Smithy.ShapeType
@_spi(SchemaBasedSerde)
import class Smithy.TimestampFormatTrait
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct
@_spi(SchemaBasedSerde)
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter

@_spi(SchemaBasedSerde)
public final class Serializer: ShapeSerializer {
    // ASCII (and UTF-8) values for significant characters in JSON
    private static let backspace: UInt8 = 8
    private static let tab: UInt8 = 9
    private static let lineFeed: UInt8 = 10
    private static let formFeed: UInt8 = 12
    private static let cr: UInt8 = 13
    private static let doubleQuote: UInt8 = 34
    private static let comma: UInt8 = 44
    private static let zero: UInt8 = 48
    private static let colon: UInt8 = 58
    private static let openingSquareBrace: UInt8 = 91
    private static let backslash: UInt8 = 92
    private static let closingSquareBrace: UInt8 = 93
    private static let b: UInt8 = 98
    private static let f: UInt8 = 102
    private static let n: UInt8 = 110
    private static let r: UInt8 = 114
    private static let t: UInt8 = 116
    private static let u: UInt8 = 117
    private static let openingCurlyBrace: UInt8 = 123
    private static let closingCurlyBrace: UInt8 = 125

    // ASCII (and UTF-8) sequences for multicharacter tokens used in JSON
    private static let trueBytes = "true".utf8
    private static let falseBytes = "false".utf8
    private static let nullBytes = "null".utf8
    private static let nan = "\"NaN\"".utf8
    private static let positiveInfinity = "\"Infinity\"".utf8
    private static let negativeInfinity = "\"-Infinity\"".utf8

    let usesJSONNameTrait: Bool
    private var _data: Data
    private var _needsComma = false

    public init(usesJSONNameTrait: Bool) {
        self.usesJSONNameTrait = usesJSONNameTrait
        // 64KB is reserved to allow for additions to data without requiring copy to a new buffer
        self._data = Data(capacity: 65536)
    }

    public func writeStruct<S>(_ schema: Schema, _ value: S) throws where S: SerializableStruct {
        try writeCommaAndStructureKeyIfNeeded(schema)

        // Save the comma state while writing the structure, and open the structure with '{'
        let savedNeedsComma = self._needsComma
        self._needsComma = false
        _data.append(Self.openingCurlyBrace)

        // Write the members of the structure
        try value.serializeMembers(schema, self)

        // Close the structure with '}', and restore the comma state
        _data.append(Self.closingCurlyBrace)
        self._needsComma = savedNeedsComma
    }

    public func writeList<E>(
        _ schema: Schema,
        _ value: [E],
        _ consumer: (E, any ShapeSerializer) throws -> Void
    ) throws {
        try writeCommaAndStructureKeyIfNeeded(schema)

        // Save the comma state while writing the list, and open the list with '['
        let savedNeedsComma = self._needsComma
        self._needsComma = false
        _data.append(Self.openingSquareBrace)

        // Write the members of the list
        for element in value {
            try consumer(element, self)
        }

        // Close the list with ']', and restore the comma state
        _data.append(Self.closingSquareBrace)
        self._needsComma = savedNeedsComma
    }

    public func writeMap<V>(
        _ schema: Schema,
        _ value: [String: V],
        _ consumer: (V, any ShapeSerializer) throws -> Void
    ) throws {
        try writeCommaAndStructureKeyIfNeeded(schema)

        // Save the comma state while writing the map, and open the map with '{'
        let savedNeedsComma = self._needsComma
        self._needsComma = false
        _data.append(Self.openingCurlyBrace)

        // Write the keys and members of the map
        for (key, value) in value {
            // Write the comma (if needed), map key and a colon
            try writeString(schema.key, key)
            _data.append(Self.colon)

            // Write the map value, saving the comma state & writing without a leading comma
            let savedNeedsComma = self._needsComma
            self._needsComma = false
            try consumer(value, self)
            self._needsComma = savedNeedsComma
        }

        // Close the map with '}', and restore the comma state
        _data.append(Self.closingCurlyBrace)
        self._needsComma = savedNeedsComma
    }

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        try writeCommaAndStructureKeyIfNeeded(schema)
        _data.append(contentsOf: value ? Self.trueBytes : Self.falseBytes)
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        try writeCommaAndStructureKeyIfNeeded(schema)
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        try writeCommaAndStructureKeyIfNeeded(schema)
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeInteger(_ schema: Schema, _ value: Int) throws {
        try writeCommaAndStructureKeyIfNeeded(schema)
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeLong(_ schema: Schema, _ value: Int) throws {
        try writeCommaAndStructureKeyIfNeeded(schema)
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        try writeFloatingPoint(schema, value)
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        try writeFloatingPoint(schema, value)
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        try writeCommaAndStructureKeyIfNeeded(schema)
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        try writeFloatingPoint(schema, value)
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        try writeCommaAndStructureKeyIfNeeded(schema)

        // Write the string's UTF-8 bytes, escaping the characters that the JSON spec
        // requires us to escape.  We don't escape forward-slash because we never embed
        // JSON in XML or use it in URLs.
        // We iterate over UTF-8 bytes rather than Characters: a grapheme cluster such as
        // "\r\n" is a single Character whose asciiValue collapses to one byte, which would
        // silently drop the carriage return.  Iterating bytes also skips grapheme-cluster
        // segmentation entirely.  UTF-8 lead & continuation bytes (>= 0x80) never require
        // escaping, so they are copied through verbatim by the default case.
        // Open and close the string with double quotes.
        _data.append(Self.doubleQuote)
        let utf8view = value.utf8
        var copyStartIndex = utf8view.startIndex
        for index in utf8view.indices {
            let byte = utf8view[index]
            if byte < 32 || byte == Self.doubleQuote || byte == Self.backslash {
                _data.append(contentsOf: utf8view[copyStartIndex..<index])
                copyStartIndex = utf8view.index(after: index)
                switch byte {
                case Self.doubleQuote:
                    appendEscaped(ascii: Self.doubleQuote)
                case Self.backslash:
                    appendEscaped(ascii: Self.backslash)
                case Self.backspace:
                    appendEscaped(ascii: Self.b)
                case Self.formFeed:
                    appendEscaped(ascii: Self.f)
                case Self.lineFeed:
                    appendEscaped(ascii: Self.n)
                case Self.cr:
                    appendEscaped(ascii: Self.r)
                case Self.tab:
                    appendEscaped(ascii: Self.t)
                case 0..<0x20:
                    // Any C0 control without a short form must be \u00XX-escaped (RFC 8259)
                    appendEscaped(ascii: Self.u)
                    appendHexByte(ascii: byte)
                default:
                    break
                }
            }
        }
        _data.append(contentsOf: value.utf8[copyStartIndex..<utf8view.endIndex])
        _data.append(Self.doubleQuote)
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        try writeCommaAndStructureKeyIfNeeded(schema)

        // Blob is written as a string surrounded by double quotes.
        // Foundation's base64EncodedData() returns UTF-8 bytes for the data in base64.
        // None of the characters used in Base64 require escaping, so the UTF-8 may be
        // copied directly into JSON.
        _data.append(Self.doubleQuote)
        _data.append(contentsOf: value.base64EncodedData())
        _data.append(Self.doubleQuote)
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        // Get the timestamp format
        let timestampFormat = schema.traits.getTrait(TimestampFormatTrait.self)?.format ?? .epochSeconds

        // Depending on format, timestamp is written either as a string or double.
        switch timestampFormat {
        case .dateTime, .httpDate:
            let dateTimeString = TimestampFormatter(format: timestampFormat).string(from: value)
            try writeString(schema, dateTimeString)
        case .epochSeconds:
            let epochSecondsString = TimestampFormatter(format: .epochSeconds).string(from: value)
            guard let epochSeconds = Double(epochSecondsString) else {
                throw SerializerError("TimestampFormatter did not return valid seconds")
            }
            try writeDouble(schema, epochSeconds)
        }
    }

    public func writeNull(_ schema: Schema) throws {
        try writeCommaAndStructureKeyIfNeeded(schema)
        _data.append(contentsOf: Self.nullBytes)
    }

    public var data: Data {
        get throws {
            // Return the encoded data, substituting '{}' if empty
            guard !_data.isEmpty else { return Data("{}".utf8) }
            return _data
        }
    }

    // MARK: - Private methods

    // An implementation of Smithy's floating point encoding, usable for any Swift floating point type.
    private func writeFloatingPoint<FP: FloatingPoint>(_ schema: Schema, _ value: FP) throws {
        try writeCommaAndStructureKeyIfNeeded(schema)

        // Write the appropriate string for .nan, .infinity, and -.infinity values
        // else just write the number
        guard !value.isNaN else {
            _data.append(contentsOf: Self.nan)
            return
        }
        switch value {
        case -FP.infinity:
            _data.append(contentsOf: Self.negativeInfinity)
        case FP.infinity:
            _data.append(contentsOf: Self.positiveInfinity)
        default:
            _data.append(contentsOf: "\(value)".utf8)
        }
    }

    private func writeCommaAndStructureKeyIfNeeded(_ schema: Schema) throws {
        // Write a comma if following another element of a structure, union, or collection.
        // needsComma is set to true after writing a comma, since all elements other than
        // the first will need a comma.
        if self._needsComma {
            _data.append(Self.comma)
        }
        self._needsComma = true

        // If this is a member of a structure or union, write the key string and a colon.
        // Never lead the key with a comma since it was just written above.
        if schema.containerType == .structure || schema.containerType == .union, let key = try objectKey(for: schema) {
            let savedNeedsComma = self._needsComma
            self._needsComma = false
            try writeString(Smithy.Prelude.stringSchema, key)
            self._needsComma = savedNeedsComma
            _data.append(Self.colon)
        }
    }

    private func objectKey(for memberSchema: Schema) throws -> String? {
        // Get jsonName, if present, for restJson.  Otherwise just the member name.
        return if usesJSONNameTrait, let jsonName = memberSchema.getTrait(JSONNameTrait.self)?.name {
            jsonName
        } else {
            memberSchema.id.member
        }
    }

    private func appendEscaped(ascii: UInt8) {
        _data.append(contentsOf: [Self.backslash, ascii])
    }

    private func appendHexByte(ascii: UInt8) {
        _data.append(contentsOf: [
            Self.zero,
            Self.zero,
            Self.digits[Int(ascii >> 4)],
            Self.digits[Int(ascii & 0x0F)],
        ])
    }

    static let digits: [UInt8] = "0123456789abcdef".compactMap { $0.asciiValue }
}
