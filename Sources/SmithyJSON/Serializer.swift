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
public class Serializer: ShapeSerializer {
    private var _data: Data
    private static let openingCurlyBrace = Character("{").utf8
    private static let closingCurlyBrace = Character("}").utf8
    private static let openingSquareBrace = Character("[").utf8
    private static let closingSquareBrace = Character("]").utf8
    private static let comma = Character(",").utf8
    private static let colon = Character(":").utf8
    private static let doubleQuote = Character("\"").utf8
    private static let trueBytes = "true".utf8
    private static let falseBytes = "false".utf8
    private static let nullBytes = "null".utf8

    public init() {
        self._data = Data(capacity: 65536)
    }

    public func writeStruct<S>(_ schema: Schema, _ value: S) throws where S: SerializableStruct {
        _data.append(contentsOf: Self.openingCurlyBrace)
        var needsComma = false
        for memberSchema in schema.members {
            guard let key = memberSchema.id.member else { continue }
            if needsComma {
                _data.append(contentsOf: Self.comma)
            }
            try writeString(schema.key, key)
            _data.append(contentsOf: Self.colon)
            try S.writeConsumer(memberSchema, value, self)
            needsComma = true
        }
        _data.append(contentsOf: Self.closingCurlyBrace)
    }

    public func writeList<E>(
        _ schema: Schema,
        _ value: [E],
        _ consumer: (E, any ShapeSerializer) throws -> Void
    ) throws {
        _data.append(contentsOf: Self.openingSquareBrace)
        var needsComma = false
        for element in value {
            if needsComma {
                _data.append(contentsOf: Self.comma)
            }
            try consumer(element, self)
            needsComma = true
        }
        _data.append(contentsOf: Self.closingSquareBrace)
    }

    public func writeMap<V>(
        _ schema: Schema,
        _ value: [String: V],
        _ consumer: (V, any ShapeSerializer) throws -> Void
    ) throws {
        _data.append(contentsOf: Self.openingCurlyBrace)
        var needsComma = false
        for (key, value) in value {
            if needsComma {
                _data.append(contentsOf: Self.comma)
            }
            try writeString(schema.key, key)
            _data.append(contentsOf: Self.colon)
            try consumer(value, self)
            needsComma = true
        }
        _data.append(contentsOf: Self.closingCurlyBrace)
    }

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        _data.append(contentsOf: value ? Self.trueBytes : Self.falseBytes)
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeInteger(_ schema: Schema, _ value: Int) throws {
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeLong(_ schema: Schema, _ value: Int) throws {
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        _data.append(contentsOf: "\(value)".utf8)
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        _data.append(contentsOf: Self.doubleQuote)
        _data.append(contentsOf: value.utf8)
        _data.append(contentsOf: Self.doubleQuote)
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
        _data.append(contentsOf: Self.nullBytes)
    }

    public var data: Data {
        get throws {
            guard !_data.isEmpty else { return Data("{}".utf8) }
            return _data
        }
    }
}
