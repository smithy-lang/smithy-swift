//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class AwsCommonRuntimeKit.CBORDecoder
import struct Foundation.Data
import struct Foundation.Date
@_spi(SmithyDocumentImpl) import struct Smithy.BigDecimalDocument
@_spi(SmithyDocumentImpl) import struct Smithy.BigIntegerDocument
@_spi(SmithyDocumentImpl) import struct Smithy.BlobDocument
@_spi(SmithyDocumentImpl) import struct Smithy.BooleanDocument
@_spi(SmithyDocumentImpl) import struct Smithy.ListDocument
@_spi(SmithyDocumentImpl) import struct Smithy.NullDocument
import class Smithy.Schema
import protocol Smithy.SmithyDocument
@_spi(SmithyDocumentImpl) import struct Smithy.StringDocument
@_spi(SmithyDocumentImpl) import struct Smithy.StringMapDocument
@_spi(SmithyDocumentImpl) import struct Smithy.TimestampDocument
import protocol SmithySerialization.DeserializableStruct
import typealias SmithySerialization.ReadStructConsumer
import typealias SmithySerialization.ReadValueConsumer
import protocol SmithySerialization.ShapeDeserializer

public struct Deserializer: ShapeDeserializer {
    let decoder: CBORDecoder

    public init(data: Data) throws {
        // Substitute an empty map if data is empty
        let resolvedData = data.isEmpty ? Data([0xBF, 0xFF]) : data
        self.decoder = try CBORDecoder(data: Array(resolvedData), rollupCollections: false)
    }

    public func readBoolean(_ schema: Schema) throws -> Bool {
        guard decoder.hasNext() else {
            throw CBORDecoderError("member \(schema.id) ended unexpectedly")
        }
        try nullCheck()
        let next = try decoder.popNext()
        guard case .bool(let value) = next else {
            throw CBORDecoderError("member \(schema.id) expected .bool but got \(next) instead")
        }
        return value
    }

    public func readBlob(_ schema: Schema) throws -> Data {
        guard decoder.hasNext() else {
            throw CBORDecoderError("member \(schema.id) ended unexpectedly")
        }
        try nullCheck()
        let next = try decoder.popNext()
        guard case .bytes(let value) = next else {
            throw CBORDecoderError("member \(schema.id) expected .bytes but got \(next) instead")
        }
        return value
    }

    public func readByte(_ schema: Schema) throws -> Int8 {
        guard decoder.hasNext() else {
            throw CBORDecoderError("member \(schema.id) ended unexpectedly")
        }
        try nullCheck()
        let next = try decoder.popNext()
        switch next {
        case .int(let value):
            return Int8(value)
        case .uint(let value):
            return Int8(value)
        default:
            throw CBORDecoderError("member \(schema.id) expected .int or .uint but got \(next) instead")
        }
    }

    public func readShort(_ schema: Schema) throws -> Int16 {
        guard decoder.hasNext() else {
            throw CBORDecoderError("member \(schema.id) ended unexpectedly")
        }
        try nullCheck()
        let next = try decoder.popNext()
        switch next {
        case .int(let value):
            return Int16(value)
        case .uint(let value):
            return Int16(value)
        default:
            throw CBORDecoderError("member \(schema.id) expected .int or .uint but got \(next) instead")
        }
    }

    public func readInteger(_ schema: Schema) throws -> Int {
        guard decoder.hasNext() else {
            throw CBORDecoderError("member \(schema.id) ended unexpectedly")
        }
        try nullCheck()
        let next = try decoder.popNext()
        switch next {
        case .int(let value):
            return Int(value)
        case .uint(let value):
            return Int(value)
        default:
            throw CBORDecoderError("member \(schema.id) expected .int or .uint but got \(next) instead")
        }
    }

    public func readLong(_ schema: Schema) throws -> Int {
        guard decoder.hasNext() else {
            throw CBORDecoderError("member \(schema.id) ended unexpectedly")
        }
        try nullCheck()
        let next = try decoder.popNext()
        switch next {
        case .int(let value):
            return Int(value)
        case .uint(let value):
            return Int(value)
        default:
            throw CBORDecoderError("member \(schema.id) expected .int or .uint but got \(next) instead")
        }
    }

    public func readFloat(_ schema: Schema) throws -> Float {
        guard decoder.hasNext() else {
            throw CBORDecoderError("member \(schema.id) ended unexpectedly")
        }
        try nullCheck()
        let next = try decoder.popNext()
        guard case .double(let value) = next else {
            throw CBORDecoderError("member \(schema.id) expected .double but got \(next) instead")
        }
        return Float(value)
    }

    public func readDouble(_ schema: Schema) throws -> Double {
        guard decoder.hasNext() else {
            throw CBORDecoderError("member \(schema.id) ended unexpectedly")
        }
        try nullCheck()
        let next = try decoder.popNext()
        guard case .double(let value) = next else {
            throw CBORDecoderError("member \(schema.id) expected .double but got \(next) instead")
        }
        return value
    }

    public func readBigInteger(_ schema: Schema) throws -> Int64 {
        guard decoder.hasNext() else {
            throw CBORDecoderError("member \(schema.id) ended unexpectedly")
        }
        try nullCheck()
        let next = try decoder.popNext()
        switch next {
        case .int(let value):
            return Int64(value)
        case .uint(let value):
            return Int64(value)
        default:
            throw CBORDecoderError("member \(schema.id) expected .int or .uint but got \(next) instead")
        }
    }

    public func readBigDecimal(_ schema: Schema) throws -> Double {
        guard decoder.hasNext() else {
            throw CBORDecoderError("member \(schema.id) ended unexpectedly")
        }
        try nullCheck()
        let next = try decoder.popNext()
        guard case .double(let value) = next else {
            throw CBORDecoderError("member \(schema.id) expected .double but got \(next) instead")
        }
        return value
    }

    public func readString(_ schema: Schema) throws -> String {
        guard decoder.hasNext() else {
            throw CBORDecoderError("member \(schema.id) ended unexpectedly")
        }
        try nullCheck()
        let next = try decoder.popNext()
        guard case .text(let value) = next else {
            throw CBORDecoderError("member \(schema.id) expected .text but got \(next) instead")
        }
        return value
    }

    public func readDocument() throws -> any SmithyDocument {
        guard decoder.hasNext() else {
            throw CBORDecoderError("document ended unexpectedly")
        }
        let next = try decoder.popNext()
        switch next {
        case .array_start(let count):
            var list = [any SmithyDocument]()
            for _ in 0..<count {
                let element = try readDocument()
                list.append(element)
            }
            return ListDocument(value: list)
        case .indef_array_start:
            var list = [any SmithyDocument]()
            while try !decoder.isIndefBreak() {
                let element = try readDocument()
                list.append(element)
            }
            _ = try decoder.popNext()
            return ListDocument(value: list)
        case .map_start(let count):
            var map = [String: any SmithyDocument]()
            for _ in 0..<count {
                let next = try decoder.popNext()
                guard case .text(let key) = next else {
                    throw CBORDecoderError("unexpected non-text element in map document")
                }
                let value = try readDocument()
                map[key] = value
            }
            return StringMapDocument(value: map)
        case .indef_map_start:
            var map = [String: any SmithyDocument]()
            while try !decoder.isIndefBreak() {
                let next = try decoder.popNext()
                guard case .text(let key) = next else {
                    throw CBORDecoderError("unexpected non-text element in map document")
                }
                let value = try readDocument()
                map[key] = value
            }
            _ = try decoder.popNext()
            return StringMapDocument(value: map)
        case .bool(let value):
            return BooleanDocument(value: value)
        case .uint(let value):
            return BigIntegerDocument(value: Int64(value))
        case .int(let value):
            return BigIntegerDocument(value: Int64(value))
        case .double(let value):
            return BigDecimalDocument(value: value)
        case .text(let value):
            return StringDocument(value: value)
        case .date(let value):
            return TimestampDocument(value: value)
        case .bytes(let value):
            return BlobDocument(value: value)
        case .null:
            return NullDocument()
        case .map, .array, .indef_bytes_start, .indef_text_start, .indef_break, .tag, .undefined:
            throw CBORDecoderError("document has unhandled CBOR element \(next)")
        }
    }

    public func readTimestamp(_ schema: Schema) throws -> Date {
        guard decoder.hasNext() else {
            throw CBORDecoderError("member \(schema.id) ended unexpectedly")
        }
        try nullCheck()
        let next = try decoder.popNext()
        guard case .date(let value) = next else {
            throw CBORDecoderError("member \(schema.id) expected .date but got \(next) instead")
        }
        return value
    }

    public func isNull() throws -> Bool {
        try decoder.isNull()
    }

    public func readNull<T>(_ schema: Schema) throws -> T? {
        let next = try decoder.popNext()
        guard case .null = next else {
            throw CBORDecoderError("member \(schema.id) expected .null but got \(next) instead")
        }
        return nil
    }

    public func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws {
        let structureSchema: Schema
        switch schema.type {
        case .structure, .union:
            structureSchema = schema
        case .member:
            guard let target = schema.target else { throw CBORDecoderError("Expected non-nil target on \(schema)") }
            structureSchema = target
        default:
            throw CBORDecoderError("unexpected schema type \(schema.type) used with readStruct")
        }

        guard decoder.hasNext() else {
            throw CBORDecoderError("struct \(schema.id) ended unexpectedly")
        }
        try nullCheck()
        let start = try decoder.popNext()
        switch start {
        case .indef_map_start:
            guard decoder.hasNext() else {
                throw CBORDecoderError("struct \(schema.id) ended unexpectedly")
            }
            var next = try decoder.popNext()
            while next != .indef_break {
                guard case .text(let memberName) = next else {
                    throw CBORDecoderError("struct \(schema.id) expected text, received \(next)")
                }
                do {
                    if let member = structureSchema.members.first(where: { $0.id.member == memberName }) {
                        try T.readConsumer(member, &value, self)
                    } else {
                        try skipValue()
                    }
                } catch is DecodedNull {
                    // skip null
                }
                guard decoder.hasNext() else {
                    throw CBORDecoderError("struct \(schema.id) ended unexpectedly")
                }
                next = try decoder.popNext()
            }
        case .map_start(let count):
            for _ in 0..<count {
                guard decoder.hasNext() else {
                    throw CBORDecoderError("Struct \(schema.id) ended unexpectedly")
                }
                let next = try decoder.popNext()
                guard case .text(let memberName) = next else {
                    throw CBORDecoderError("expected CBOR text \(schema.id) ended unexpectedly")
                }

                do {
                    if let member = structureSchema.members.first(where: { $0.id.member == memberName }) {
                        try T.readConsumer(member, &value, self)
                    } else {
                        try skipValue()
                    }
                } catch is DecodedNull {
                    // skip null
                }
            }
        default:
            throw CBORDecoderError("Struct \(schema.id) did not start with .map_start or .indef_map_start")
        }
    }

    private func skipValue() throws {
        let next = try decoder.popNext()
        switch next {
        case .array_start(let count):
            for _ in 0..<count {
                try skipValue()
            }
        case .indef_array_start:
            while try !decoder.isIndefBreak() {
                try skipValue()
            }
            _ = try decoder.popNext()
        case .map_start(let count):
            for _ in 0..<count {
                try skipValue() // skip key
                try skipValue() // skip value
            }
        case .indef_map_start:
            while try !decoder.isIndefBreak() {
                try skipValue() // skip key
                try skipValue() // skip value
            }
            _ = try decoder.popNext()
        case .array, .bool, .bytes, .date, .double, .int, .map, .null, .tag, .text, .uint, .undefined:
            break
        case .indef_break, .indef_bytes_start, .indef_text_start:
            throw CBORDecoderError("unexpected \(next)")
        }
    }

    public func readList<E>(_ schema: Schema, _ list: inout [E], _ consumer: ReadValueConsumer<E>) throws {
        guard decoder.hasNext() else {
            throw CBORDecoderError("List \(schema.id) ended unexpectedly")
        }
        try nullCheck()
        let start = try decoder.popNext()
        switch start {
        case .indef_array_start:
            guard decoder.hasNext() else {
                throw CBORDecoderError("List \(schema.id) ended unexpectedly")
            }
            while try !decoder.isIndefBreak() {
                do {
                    let nextElement = try consumer(self)
                    list.append(nextElement)
                } catch is DecodedNull {
                    // skip the null
                }
                guard decoder.hasNext() else {
                    throw CBORDecoderError("struct \(schema.id) ended unexpectedly")
                }
            }
            // pop the indef_break
            _ = try decoder.popNext()
        case .array_start(let count):
            for _ in 0..<count {
                do {
                    let nextElement = try consumer(self)
                    list.append(nextElement)
                } catch is DecodedNull {
                    // skip the null
                }
            }
        default:
            throw CBORDecoderError("List \(schema.id) did not start with .array_start or .indef_array_start")
        }
    }

    public func readMap<V>( _ schema: Schema, _ map: inout [String: V], _ consumer: ReadValueConsumer<V>) throws {
        guard decoder.hasNext() else {
            throw CBORDecoderError("Map \(schema.id) ended unexpectedly")
        }
        try nullCheck()
        let start = try decoder.popNext()
        switch start {
        case .indef_map_start:
            guard decoder.hasNext() else {
                throw CBORDecoderError("Map \(schema.id) ended unexpectedly")
            }
            var next = try decoder.popNext()
            while next != .indef_break {
                guard case .text(let key) = next else {
                    throw CBORDecoderError("map \(schema.id) expected text, received \(next)")
                }
                do {
                    let value = try consumer(self)
                    map[key] = value
                } catch is DecodedNull {
                    // skip the null
                }
                guard decoder.hasNext() else {
                    throw CBORDecoderError("map \(schema.id) ended unexpectedly")
                }
                next = try decoder.popNext()
            }
        case .map_start(let count):
            for _ in 0..<count {
                let next = try decoder.popNext()
                guard case .text(let key) = next else {
                    throw CBORDecoderError("map \(schema.id) expected text, received \(next)")
                }
                do {
                    let value = try consumer(self)
                    map[key] = value
                } catch is DecodedNull {
                    // skip the null
                }
            }
        default:
            throw CBORDecoderError("Map \(schema.id) did not start with .map_start or .indef_map_start")
        }
    }

    /// Container size is not implemented & returns unknown size, even for definite CBOR maps & arrays
    public var containerSize: Int = -1

    private func nullCheck() throws {
        if try decoder.isNull() {
            _ = try decoder.popNext()
            throw DecodedNull()
        }
    }
}
