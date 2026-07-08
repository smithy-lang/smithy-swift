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
@_spi(SchemaBasedSerde)
@_spi(SmithyDocumentImpl) import Smithy
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.DeserializableStruct
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeDeserializer
import struct SmithySerialization.UnexpectedNullError
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter

@_spi(SchemaBasedSerde)
public final class Deserializer: ShapeDeserializer {
    let value: JSONValue
    let usesJSONNameTrait: Bool

    public init(usesJSONNameTrait: Bool, data: Data) throws {
        self.usesJSONNameTrait = usesJSONNameTrait
        guard !data.isEmpty else {
            self.value = .object([:])
            return
        }
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        let node = try JSONValue(from: jsonObject)
        self.value = node
    }

    init(usesJSONNameTrait: Bool, node: JSONValue) {
        self.usesJSONNameTrait = usesJSONNameTrait
        self.value = node
    }

    public func readStruct<T>(_ schema: Schema, _ value: inout T) throws where T: DeserializableStruct {
        try nullCheck()
        guard case .object(let object) = self.value else { throw SerializerError("Expected object") }
        let memberSchemas = schema.members

        // Pre-fill members that have the required trait but no default with a zero/false/empty value.
        for member in memberSchemas where member.hasTrait(RequiredTrait.self) && !member.hasTrait(DefaultTrait.self) {
            let deserializer: Deserializer
            switch member.target!.type {
            case .structure, .union, .map:
                deserializer = Deserializer(usesJSONNameTrait: usesJSONNameTrait, node: .object([:]))
            case .list, .set:
                deserializer = Deserializer(usesJSONNameTrait: usesJSONNameTrait, node: .list([]))
            case .string:
                deserializer = Deserializer(usesJSONNameTrait: usesJSONNameTrait, node: .string(""))
            case .byte, .short, .integer, .long, .bigInteger, .float, .double, .bigDecimal, .timestamp:
                deserializer = Deserializer(usesJSONNameTrait: usesJSONNameTrait, node: .number(0))
            case .boolean:
                deserializer = Deserializer(usesJSONNameTrait: usesJSONNameTrait, node: .bool(false))
            case .blob:
                deserializer = Deserializer(usesJSONNameTrait: usesJSONNameTrait, node: .string(""))
            default:
                continue
            }
            try value.deserializeMember(member, deserializer)
        }

        // Iterate over JSON elements of object & call consumer with the appropriate member.
        for (key, val) in object where val != .null { // skip null values in structures
            guard let memberSchema = try match(key: key, memberSchemas: memberSchemas) else { continue }
            let memberDeserializer = Deserializer(usesJSONNameTrait: usesJSONNameTrait, node: val)
            try value.deserializeMember(memberSchema, memberDeserializer)
        }
    }

    public func readList<E>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> E) throws -> [E] {
        try nullCheck()
        guard case .list(let list) = value else { throw SerializerError("Expected list") }
        return try list.compactMap {
            do {
                return try consumer(Deserializer(usesJSONNameTrait: usesJSONNameTrait, node: $0))
            } catch is UnexpectedNullError {
                // JSON deserializer "tolerates" nulls in non-sparse lists.
                // This nil will be compacted out of the returned list.
                return nil
            }
        }
    }

    public func readMap<V>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> V) throws -> [String: V] {
        try nullCheck()
        guard case .object(let map) = value else { throw SerializerError("Expected map") }
        return try map.compactMapValues {
            do {
                return try consumer(Deserializer(usesJSONNameTrait: usesJSONNameTrait, node: $0))
            } catch is UnexpectedNullError {
                // JSON deserializer "tolerates" nulls in non-sparse maps.
                // This nil will be compacted out of the returned map.
                return nil
            }
        }
    }

    public func readBoolean(_ schema: Schema) throws -> Bool {
        try nullCheck()
        guard case .bool(let bool) = value else { throw SerializerError("Expected bool") }
        return bool
    }

    public func readBlob(_ schema: Schema) throws -> Data {
        try nullCheck()
        guard case .string(let string) = value else { throw SerializerError("Expected string") }
        guard let data = Data(base64Encoded: string) else { throw SerializerError("String is not valid base64") }
        return data
    }

    public func readByte(_ schema: Schema) throws -> Int8 {
        try nullCheck()
        guard case .number(let number) = value else { throw SerializerError("Expected number") }
        guard let byte = Int8(exactly: number.intValue) else { throw SerializerError("Number is not Int8") }
        return byte
    }

    public func readShort(_ schema: Schema) throws -> Int16 {
        try nullCheck()
        guard case .number(let number) = value else { throw SerializerError("Expected number") }
        guard let short = Int16(exactly: number.intValue) else { throw SerializerError("Number is not Int16") }
        return short
    }

    public func readInteger(_ schema: Schema) throws -> Int {
        try nullCheck()
        guard case .number(let number) = value else { throw SerializerError("Expected number") }
        guard let int = Int(exactly: number.intValue) else { throw SerializerError("Number is not Int") }
        return int
    }

    public func readLong(_ schema: Schema) throws -> Int {
        try nullCheck()
        guard case .number(let number) = value else { throw SerializerError("Expected number") }
        guard let int = Int(exactly: number.int64Value) else { throw SerializerError("Number is not Int") }
        return int
    }

    public func readFloat(_ schema: Schema) throws -> Float {
        try nullCheck()
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
        try nullCheck()
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
        try nullCheck()
        guard case .number(let number) = value else { throw SerializerError("Expected number") }
        guard let bigInt = Int64(exactly: number.int64Value) else { throw SerializerError("Number is not Int64") }
        return bigInt
    }

    public func readBigDecimal(_ schema: Schema) throws -> Double {
        try readDouble(schema)
    }

    public func readString(_ schema: Schema) throws -> String {
        try nullCheck()
        guard case .string(let string) = value else { throw SerializerError("Expected string") }
        return string
    }

    public func readDocument(_ schema: Schema) throws -> any SmithyDocument {
        switch value {
        case .object(let object):
            let documentObject = try object.mapValues { value in
                let deserializer = Deserializer(usesJSONNameTrait: usesJSONNameTrait, node: value)
                return try deserializer.readDocument(schema)
            }
            return StringMapDocument(value: documentObject)
        case .list(let list):
            let documentList = try list.map { value in
                let deserializer = Deserializer(usesJSONNameTrait: usesJSONNameTrait, node: value)
                return try deserializer.readDocument(schema)
            }
            return ListDocument(value: documentList)
        case .number(let number):
            return BigDecimalDocument(value: number.doubleValue)
        case .bool(let bool):
            return BooleanDocument(value: bool)
        case .string(let string):
            return StringDocument(value: string)
        case .null:
            return NullDocument()
        }
    }

    public func readTimestamp(_ schema: Schema) throws -> Date {
        try nullCheck()
        let timestampFormat = schema.getTrait(TimestampFormatTrait.self)?.format ?? .epochSeconds
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

    // MARK: - Private methods

    private func match(key: String, memberSchemas: [Schema]) throws -> Schema? {
        memberSchemas.first { memberSchema in
            if usesJSONNameTrait, let jsonNameTrait = memberSchema.getTrait(JSONNameTrait.self) {
                jsonNameTrait.name == key
            } else {
                memberSchema.id.member == key
            }
        }
    }

    private func nullCheck() throws {
        if case .null = self.value {
            throw UnexpectedNullError()
        }
    }
}

extension SerializerError {
    static var floatingPointError: Self { SerializerError("Expected number, NaN, Infinity, -Infinity") }
}
