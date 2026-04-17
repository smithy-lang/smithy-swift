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
@_spi(SmithyDocumentImpl) import Smithy
import protocol SmithySerialization.DeserializableStruct
import struct SmithySerialization.SerializerError
import protocol SmithySerialization.ShapeDeserializer
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter

public class Deserializer: ShapeDeserializer {
    let value: JSONValue

    public init(data: Data) throws {
        guard !data.isEmpty else {
            self.value = .object([:])
            return
        }
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        let node = try JSONValue(from: jsonObject)
        self.value = node
    }

    init(node: JSONValue) {
        self.value = node
    }

    public func readStruct<T>(_ schema: Schema, _ value: inout T) throws where T: DeserializableStruct {
        guard case .object(let object) = self.value else { throw SerializerError("Expected object") }
        let members = schema.members

        // Pre-fill members that have the required trait but no default with a zero/false/empty value.
        for member in members where member.hasTrait(RequiredTrait.self) && !member.hasTrait(DefaultTrait.self) {
            let deserializer: Deserializer
            switch member.target!.type {
            case .structure, .union, .map:
                deserializer = Deserializer(node: .object([:]))
            case .list, .set:
                deserializer = Deserializer(node: .list([]))
            case .string:
                deserializer = Deserializer(node: .string(""))
            case .byte, .short, .integer, .long, .bigInteger, .float, .double, .bigDecimal, .timestamp:
                deserializer = Deserializer(node: .number(0))
            case .boolean:
                deserializer = Deserializer(node: .bool(false))
            case .blob:
                deserializer = Deserializer(node: .string(""))
            default:
                continue
            }
            try T.readConsumer(member, &value, deserializer)
        }

        // Iterate over JSON elements of object & call consumer with the appropriate member.
        for (key, val) in object where val != .null { // skip null values in structures
            guard let memberSchema = members.first(where: { $0.id.member == key }) else { continue }
            let memberDeserializer = Deserializer(node: val)
            try T.readConsumer(memberSchema, &value, memberDeserializer)
        }
    }

    public func readList<E>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> E) throws -> [E] {
        guard case .list(let list) = value else { throw SerializerError("Expected list") }
        return try list.map { try consumer(Deserializer(node: $0)) }
    }

    public func readMap<V>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> V) throws -> [String: V] {
        guard case .object(let map) = value else { throw SerializerError("Expected map") }
        return try map.mapValues { try consumer(Deserializer(node: $0)) }
    }

    public func readBoolean(_ schema: Schema) throws -> Bool {
        guard case .bool(let bool) = value else { throw SerializerError("Expected bool") }
        return bool
    }

    public func readBlob(_ schema: Schema) throws -> Data {
        guard case .string(let string) = value else { throw SerializerError("Expected string") }
        guard let data = Data(base64Encoded: string) else { throw SerializerError("String is not valid base64") }
        return data
    }

    public func readByte(_ schema: Schema) throws -> Int8 {
        guard case .number(let number) = value else { throw SerializerError("Expected number") }
        guard let byte = Int8(exactly: number.intValue) else { throw SerializerError("Number is not Int8") }
        return byte
    }

    public func readShort(_ schema: Schema) throws -> Int16 {
        guard case .number(let number) = value else { throw SerializerError("Expected number") }
        guard let short = Int16(exactly: number.intValue) else { throw SerializerError("Number is not Int16") }
        return short
    }

    public func readInteger(_ schema: Schema) throws -> Int {
        guard case .number(let number) = value else { throw SerializerError("Expected number") }
        guard let int = Int(exactly: number.intValue) else { throw SerializerError("Number is not Int") }
        return int
    }

    public func readLong(_ schema: Schema) throws -> Int {
        guard case .number(let number) = value else { throw SerializerError("Expected number") }
        guard let int = Int(exactly: number.int64Value) else { throw SerializerError("Number is not Int") }
        return int
    }

    public func readFloat(_ schema: Schema) throws -> Float {
        switch value {
        case .number(let number):
            return Float(number.doubleValue)
        case .string(let string):
            return try floatingPointValue(string: string)
        default:
            throw SerializerError.floatingPointError
        }
    }

    public func readDouble(_ schema: Schema) throws -> Double {
        switch value {
        case .number(let number):
            return number.doubleValue
        case .string(let string):
            return try floatingPointValue(string: string)
        default:
            throw SerializerError.floatingPointError
        }
    }

    private func floatingPointValue<T: FloatingPoint>(string: String) throws -> T {
        switch string {
        case "NaN":
            return T.nan
        case "Infinity":
            return T.infinity
        case "-Infinity":
            return -T.infinity
        default:
            throw SerializerError.floatingPointError
        }
    }

    public func readBigInteger(_ schema: Schema) throws -> Int64 {
        guard case .number(let number) = value else { throw SerializerError("Expected number") }
        guard let bigInt = Int64(exactly: number.int64Value) else { throw SerializerError("Number is not Int64") }
        return bigInt
    }

    public func readBigDecimal(_ schema: Schema) throws -> Double {
        try readDouble(schema)
    }

    public func readString(_ schema: Schema) throws -> String {
        guard case .string(let string) = value else { throw SerializerError("Expected string") }
        return string
    }

    public func readDocument(_ schema: Schema) throws -> Smithy.Document {
        switch value {
        case .object(let object):
            let documentObject = try object.mapValues { value in
                let deserializer = Deserializer(node: value)
                return try deserializer.readDocument(schema)
            }
            return Document(StringMapDocument(value: documentObject))
        case .list(let list):
            let documentList = try list.map { value in
                let deserializer = Deserializer(node: value)
                return try deserializer.readDocument(schema)
            }
            return Document(ListDocument(value: documentList))
        case .number(let number):
            return Document(BigDecimalDocument(value: number.doubleValue))
        case .bool(let bool):
            return Document(BooleanDocument(value: bool))
        case .string(let string):
            return Document(StringDocument(value: string))
        case .null:
            return Document(NullDocument())
        }
    }

    public func readTimestamp(_ schema: Schema) throws -> Date {
        let timestampFormat = try schema.getTrait(TimestampFormatTrait.self)?.format ?? .epochSeconds
        switch timestampFormat {
        case .dateTime:
            guard case .string(let string) = value else {
                throw SerializerError("Expected string for dateTime timestamp")
            }
            guard let date = TimestampFormatter(format: .dateTime).date(from: string) else {
                throw SerializerError("Timestamp string \"\(string)\" is invalid for type dateTime")
            }
            return date
        case .httpDate:
            guard case .string(let string) = value else {
                throw SerializerError("Expected string for httpDate timestamp")
            }
            guard let date = TimestampFormatter(format: .httpDate).date(from: string) else {
                throw SerializerError("Timestamp string \"\(string)\" is invalid for type httpDate")
            }
            return date
        case .epochSeconds:
            guard case .number(let number) = value else {
                throw SerializerError("Expected number for epochSeconds timestamp")
            }
            return Date(timeIntervalSince1970: number.doubleValue)
        }
    }

    public func readNull<T>(_ schema: Schema) throws -> T? {
        // no action required
        return nil
    }

    public func isNull() throws -> Bool {
        value == .null
    }

    public var containerSize: Int {
        switch value {
        case .object(let object):
            return object.count
        case .list(let list):
            return list.count
        default:
            return -1
        }
    }

}

extension SerializerError {
    static var floatingPointError: Self { SerializerError("Expected number, NaN, Infinity, -Infinity") }
}
