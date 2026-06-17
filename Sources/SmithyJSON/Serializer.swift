//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import class Foundation.JSONSerialization
import class Foundation.NSNumber
import struct Smithy.Document
@_spi(SchemaBasedSerde)
import struct Smithy.JSONNameTrait
@_spi(SchemaBasedSerde)
import enum Smithy.Prelude
@_spi(SchemaBasedSerde)
import struct Smithy.Schema
@_spi(SchemaBasedSerde)
import struct Smithy.TimestampFormatTrait
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct
@_spi(SchemaBasedSerde)
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter

@_spi(SchemaBasedSerde)
public final class Serializer: ShapeSerializer {
    private static let backspace = Character(Unicode.Scalar(0x0008)!)
    private static let formFeed = Character(Unicode.Scalar(0x000C)!)
    private static let lineFeed = Character(Unicode.Scalar(0x000A)!)
    private static let cr = Character(Unicode.Scalar(0x000D)!)
    private static let tab = Character(Unicode.Scalar(0x0009)!)
    private static let b = Character("b")
    private static let f = Character("f")
    private static let n = Character("n")
    private static let r = Character("r")
    private static let t = Character("t")
    private static let openingCurlyBrace = Character("{")
    private static let closingCurlyBrace = Character("}")
    private static let openingSquareBrace = Character("[")
    private static let closingSquareBrace = Character("]")
    private static let comma = Character(",")
    private static let colon = Character(":")
    private static let doubleQuote = Character("\"")
    private static let forwardSlash = Character("/")
    private static let backslash = Character("\\")
    private static let trueBytes = "true".utf8
    private static let falseBytes = "false".utf8
    private static let nullBytes = "null".utf8

    let usesJSONNameTrait: Bool
    private var _data: Data
    private var _needsComma = false
    private var _key: String?
    private var _keySchema: Schema?

    public init(usesJSONNameTrait: Bool) {
        self.usesJSONNameTrait = usesJSONNameTrait
        self._data = Data(capacity: 65536)
    }

    public func writeStruct<S>(_ schema: Schema, _ value: S) throws where S: SerializableStruct {
        try writeCommaIfNeeded()
        let savedNeedsComma = self._needsComma
        self._needsComma = false
        self._keySchema = Smithy.Prelude.stringSchema
        _data.append(contentsOf: Self.openingCurlyBrace.utf8)
        for memberSchema in schema.members {
            defer { self._key = nil }
            guard let key = try objectKey(for: memberSchema) else { continue }
            self._key = key
            try S.writeConsumer(memberSchema, value, self)
        }
        _data.append(contentsOf: Self.closingCurlyBrace.utf8)
        self._needsComma = savedNeedsComma
    }

    public func writeList<E>(
        _ schema: Schema,
        _ value: [E],
        _ consumer: (E, any ShapeSerializer) throws -> Void
    ) throws {
        try writeCommaIfNeeded()
        let savedNeedsComma = self._needsComma
        self._needsComma = false
        _data.append(contentsOf: Self.openingSquareBrace.utf8)
        for element in value {
            try consumer(element, self)
            self._needsComma = true
        }
        _data.append(contentsOf: Self.closingSquareBrace.utf8)
        self._needsComma = savedNeedsComma
    }

    public func writeMap<V>(
        _ schema: Schema,
        _ value: [String: V],
        _ consumer: (V, any ShapeSerializer) throws -> Void
    ) throws {
        try writeCommaIfNeeded()
        let savedNeedsComma = self._needsComma
        self._needsComma = false
        self._keySchema = schema.key
        _data.append(contentsOf: Self.openingCurlyBrace.utf8)
        for (key, value) in value {
            defer { self._key = nil }
            self._key = key
            try consumer(value, self)
        }
        _data.append(contentsOf: Self.closingCurlyBrace.utf8)
        self._needsComma = savedNeedsComma
    }

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        try writeCommaIfNeeded()
        _data.append(contentsOf: value ? Self.trueBytes : Self.falseBytes)
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        try writeCommaIfNeeded()
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        try writeCommaIfNeeded()
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeInteger(_ schema: Schema, _ value: Int) throws {
        try writeCommaIfNeeded()
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeLong(_ schema: Schema, _ value: Int) throws {
        try writeCommaIfNeeded()
        let str = "\(value)"
        _data.append(contentsOf: str.utf8)
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        guard !value.isNaN else {
            try writeString(Smithy.Prelude.stringSchema, "NaN")
            return
        }
        switch value {
        case -Float.infinity:
            try writeString(Smithy.Prelude.stringSchema, "-Infinity")
        case Float.infinity:
            try writeString(Smithy.Prelude.stringSchema, "Infinity")
        default:
            try writeCommaIfNeeded()
            _data.append(contentsOf: "\(value)".utf8)
        }
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        guard !value.isNaN else {
            try writeString(Smithy.Prelude.stringSchema, "NaN")
            return
        }
        switch value {
        case -Double.infinity:
            try writeString(Smithy.Prelude.stringSchema, "-Infinity")
        case Double.infinity:
            try writeString(Smithy.Prelude.stringSchema, "Infinity")
        default:
            try writeCommaIfNeeded()
            _data.append(contentsOf: "\(value)".utf8)
        }
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        try writeCommaIfNeeded()
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        guard !value.isNaN else {
            try writeString(Smithy.Prelude.stringSchema, "NaN")
            return
        }
        switch value {
        case -Double.infinity:
            try writeString(Smithy.Prelude.stringSchema, "-Infinity")
        case Double.infinity:
            try writeString(Smithy.Prelude.stringSchema, "Infinity")
        default:
            try writeCommaIfNeeded()
            _data.append(contentsOf: "\(value)".utf8)
        }
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        try writeCommaIfNeeded()
        _data.append(contentsOf: Self.doubleQuote.utf8)
        for character in value {
            switch character {
            case Self.doubleQuote:
                _data.append(contentsOf: Self.backslash.utf8)
                _data.append(contentsOf: Self.doubleQuote.utf8)
            case Self.backslash:
                _data.append(contentsOf: Self.backslash.utf8)
                _data.append(contentsOf: Self.backslash.utf8)
            case Self.forwardSlash:
                _data.append(contentsOf: Self.backslash.utf8)
                _data.append(contentsOf: Self.forwardSlash.utf8)
            case Self.backspace:
                _data.append(contentsOf: Self.backslash.utf8)
                _data.append(contentsOf: Self.b.utf8)
            case Self.formFeed:
                _data.append(contentsOf: Self.backslash.utf8)
                _data.append(contentsOf: Self.f.utf8)
            case Self.lineFeed:
                _data.append(contentsOf: Self.backslash.utf8)
                _data.append(contentsOf: Self.n.utf8)
            case Self.cr:
                _data.append(contentsOf: Self.backslash.utf8)
                _data.append(contentsOf: Self.r.utf8)
            case Self.tab:
                _data.append(contentsOf: Self.backslash.utf8)
                _data.append(contentsOf: Self.t.utf8)
            default:
                _data.append(contentsOf: character.utf8)
            }
        }
        _data.append(contentsOf: Self.doubleQuote.utf8)
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        try writeString(schema, value.base64EncodedString())
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        let timestampFormat: TimestampFormatTrait.Format
        if schema.type == .member {
            let memberTraits = schema.traits
            let memberTimestampFormat = try memberTraits.getTrait(TimestampFormatTrait.self)?.format
            let targetTraits = schema.target!.traits
            let targetTimestampFormat = try targetTraits.getTrait(TimestampFormatTrait.self)?.format
            timestampFormat = memberTimestampFormat ?? targetTimestampFormat ?? .epochSeconds
        } else {
            timestampFormat = try schema.traits.getTrait(TimestampFormatTrait.self)?.format ?? .epochSeconds
        }
        switch timestampFormat {
        case .dateTime:
            let dateTimeString = TimestampFormatter(format: .dateTime).string(from: value)
            try writeString(schema, dateTimeString)
        case .httpDate:
            let httpDateString = TimestampFormatter(format: .httpDate).string(from: value)
            try writeString(schema, httpDateString)
        case .epochSeconds:
            let epochSecondsString = TimestampFormatter(format: .epochSeconds).string(from: value)
            guard let epochSeconds = Double(epochSecondsString) else {
                throw SerializerError("TimestampFormatter did not return valid seconds")
            }
            try writeDouble(schema, epochSeconds)
        }
    }

    public func writeNull(_ schema: Schema) throws {
        try writeCommaIfNeeded()
        _data.append(contentsOf: Self.nullBytes)
    }

    public var data: Data {
        get throws {
            guard !_data.isEmpty else { return Data("{}".utf8) }
            return _data
        }
    }

    // MARK: - Private methods

    private func objectKey(for memberSchema: Schema) throws -> String? {
        return if usesJSONNameTrait, let jsonName = try memberSchema.getTrait(JSONNameTrait.self)?.name {
            jsonName
        } else {
            memberSchema.id.member
        }
    }

    private func writeCommaIfNeeded() throws {
        if self._needsComma {
            _data.append(contentsOf: Self.comma.utf8)
        }
        if let key = self._key, let keySchema = self._keySchema {
            self._needsComma = false
            self._key = nil
            try writeString(keySchema, key)
            _data.append(contentsOf: Self.colon.utf8)
            self._needsComma = true
        }
    }
}
