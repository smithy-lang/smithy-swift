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
import class Foundation.NSDecimalNumber
@_spi(SchemaBasedSerde)
@_spi(SmithyDocumentImpl) import Smithy
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.DeserializableStruct
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeDeserializer
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter

@_spi(SchemaBasedSerde)
public class NewDeserializer: ShapeDeserializer {
    let parser: JSONStreamParser

    public init(data: Data) throws {
        let resolvedData = data.isEmpty ? Data("{}".utf8) : data
        self.parser = JSONStreamParser(input: resolvedData)
    }

    private func check(event: Event) throws {
        if case .null = event { throw JSONDeserializerError.decodedNull }
        if case .endList = event { throw JSONDeserializerError.decodedEndList }
        if case .endObject = event { throw JSONDeserializerError.decodedEndObject }
    }

    public func readStruct<T>(_ schema: Schema, _ value: inout T) throws where T: DeserializableStruct {
        let startObjectEvent = try parser.parse()
        try check(event: startObjectEvent)
        guard case .startObject = startObjectEvent else {
            throw SerializerError("Expected .startObject")
        }
        let members = schema.members

        // Pre-fill members that have the required trait but no default with a zero/false/empty value.
        for member in members where member.hasTrait(RequiredTrait.self) && !member.hasTrait(DefaultTrait.self) {
            switch member.target!.type {
            case .structure, .union, .map, .list, .set, .string, .byte, .short,
                 .integer, .long, .bigInteger, .float, .double, .bigDecimal,
                 .timestamp, .boolean, .blob:
                let deserializer = DefaultDeserializer()
                try T.readConsumer(member, &value, deserializer)
            default:
                continue
            }
        }

        // Iterate over JSON elements of object & call consumer with the appropriate member.
        var keyEvent = try parser.parse()
        while case .key(let key) = keyEvent {
            if let matchingMemberSchema = members.first(where: { $0.id.member == key }) {
                do {
                    try T.readConsumer(matchingMemberSchema, &value, self)
                } catch JSONDeserializerError.decodedNull {
                    // no-op, skip null values in structures
                }
            } else {
                try parser.parseToNextElement()
            }

            // Get the next key to start the top of the loop
            keyEvent = try parser.parse()
        }

        // Verify that the endObject event was received when expected
        let endObjectEvent = keyEvent
        guard case .endObject = endObjectEvent else {
            throw SerializerError("Expected .endObject")
        }
    }

    public func readList<E>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> E) throws -> [E] {
        let startListEvent = try parser.parse()
        try check(event: startListEvent)
        guard case .startList = startListEvent else {
            throw SerializerError("Expected .startList")
        }
        return try finishList(consumer: consumer)
    }

    private func finishList<E>(consumer: (any ShapeDeserializer) throws -> E) throws -> [E] {
        var array = [E]()
        var isAtEnd = false
        while !isAtEnd {
            do {
                array.append(try consumer(self))
            } catch JSONDeserializerError.decodedEndList {
                isAtEnd = true
            }
        }
        return array
    }

    public func readMap<V>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> V) throws -> [String: V] {
        let startMapEvent = try parser.parse()
        try check(event: startMapEvent)
        guard case .startObject = startMapEvent else {
            throw SerializerError("Expected .startObject")
        }
        return try finishMap(consumer: consumer)
    }

    private func finishMap<V>(consumer: (any ShapeDeserializer) throws -> V) throws -> [String: V] {
        var map = [String: V]()
        var isAtEnd = false
        while !isAtEnd {
            let keyEvent = try parser.parse()
            switch keyEvent {
            case .key(let key):
                map[key] = try consumer(self)
            case .endObject:
                isAtEnd = true
            default:
                throw SerializerError("Unexpected event in map")
            }
        }
        return map
    }

    public func readBoolean(_ schema: Schema) throws -> Bool {
        let booleanEvent = try parser.parse()
        try check(event: booleanEvent)
        guard case .boolean(let bool) = booleanEvent else {
            throw SerializerError("Expected .boolean")
        }
        return bool
    }

    public func readBlob(_ schema: Schema) throws -> Data {
        let blobEvent = try parser.parse()
        try check(event: blobEvent)
        guard case .string(let string) = blobEvent else { throw SerializerError("Expected string") }
        guard let data = Data(base64Encoded: string) else { throw SerializerError("String is not valid base64") }
        return data
    }

    public func readByte(_ schema: Schema) throws -> Int8 {
        let byteEvent = try parser.parse()
        try check(event: byteEvent)
        guard case .number(let number) = byteEvent else { throw SerializerError("Expected number") }
        guard let byte = Int8(exactly: (number as NSDecimalNumber).intValue) else { throw SerializerError("Number is not Int8") }
        return byte
    }

    public func readShort(_ schema: Schema) throws -> Int16 {
        let shortEvent = try parser.parse()
        try check(event: shortEvent)
        guard case .number(let number) = shortEvent else { throw SerializerError("Expected number") }
        guard let short = Int16(exactly: (number as NSDecimalNumber).intValue) else { throw SerializerError("Number is not Int16") }
        return short
    }

    public func readInteger(_ schema: Schema) throws -> Int {
        let intEvent = try parser.parse()
        try check(event: intEvent)
        guard case .number(let number) = intEvent else { throw SerializerError("Expected number") }
        guard let int = Int(exactly: (number as NSDecimalNumber).intValue) else { throw SerializerError("Number is not Int") }
        return int
    }

    public func readLong(_ schema: Schema) throws -> Int {
        let longEvent = try parser.parse()
        try check(event: longEvent)
        guard case .number(let number) = longEvent else { throw SerializerError("Expected number") }
        guard let int = Int(exactly: (number as NSDecimalNumber).int64Value) else { throw SerializerError("Number is not Int") }
        return int
    }

    public func readFloat(_ schema: Schema) throws -> Float {
        let floatEvent = try parser.parse()
        try check(event: floatEvent)
        switch floatEvent {
        case .number(let number):
            return (number as NSDecimalNumber).floatValue
        case .string(let string):
            return try floatingPointValue(string: string)
        default:
            throw SerializerError.floatingPointError
        }
    }

    public func readDouble(_ schema: Schema) throws -> Double {
        let doubleEvent = try parser.parse()
        try check(event: doubleEvent)
        switch doubleEvent {
        case .number(let number):
            return (number as NSDecimalNumber).doubleValue
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
        let bigIntegerEvent = try parser.parse()
        try check(event: bigIntegerEvent)
        guard case .number(let number) = bigIntegerEvent else { throw SerializerError("Expected number") }
        guard let bigInt = Int64(exactly: (number as NSDecimalNumber).int64Value) else { throw SerializerError("Number is not Int64") }
        return bigInt
    }

    public func readBigDecimal(_ schema: Schema) throws -> Double {
        try readDouble(schema)
    }

    public func readString(_ schema: Schema) throws -> String {
        let stringEvent = try parser.parse()
        try check(event: stringEvent)
        guard case .string(let string) = stringEvent else { throw SerializerError("Expected string") }
        return string
    }

    public func readDocument(_ schema: Schema) throws -> Smithy.Document {
        let documentEvent = try parser.parse()
        try check(event: documentEvent)
        switch documentEvent {
        case .startObject:
            let documentObject = try finishMap { deserializer in
                try deserializer.readDocument(schema)
            }
            return Document(StringMapDocument(value: documentObject))
        case .startList:
            let documentList = try finishList { deserializer in
                try deserializer.readDocument(schema)
            }
            return Document(ListDocument(value: documentList))
        case .number(let number):
            return Document(BigDecimalDocument(value: (number as NSDecimalNumber).doubleValue))
        case .boolean(let bool):
            return Document(BooleanDocument(value: bool))
        case .string(let string):
            return Document(StringDocument(value: string))
        case .null:
            return Document(NullDocument())
        case .endObject, .endList, .key:
            throw SerializerError("Unexpected event in document")
        }
    }

    public func readTimestamp(_ schema: Schema) throws -> Date {
        let timestampEvent = try parser.parse()
        try check(event: timestampEvent)
        let timestampFormat = try schema.getTrait(TimestampFormatTrait.self)?.format ?? .epochSeconds
        switch timestampFormat {
        case .dateTime:
            guard case .string(let string) = timestampEvent else {
                throw SerializerError("Expected string for dateTime timestamp")
            }
            guard let date = TimestampFormatter(format: .dateTime).date(from: string) else {
                throw SerializerError("Timestamp string \"\(string)\" is invalid for type dateTime")
            }
            return date
        case .httpDate:
            guard case .string(let string) = timestampEvent else {
                throw SerializerError("Expected string for httpDate timestamp")
            }
            guard let date = TimestampFormatter(format: .httpDate).date(from: string) else {
                throw SerializerError("Timestamp string \"\(string)\" is invalid for type httpDate")
            }
            return date
        case .epochSeconds:
            guard case .number(let number) = timestampEvent else {
                throw SerializerError("Expected number for epochSeconds timestamp")
            }
            return Date(timeIntervalSince1970: (number as NSDecimalNumber).doubleValue)
        }
    }

    public func readNull<T>(_ schema: Schema) throws -> T? {
        let nullEvent = try parser.parse()
        guard case .null = nullEvent else {
            throw SerializerError("Expected .null")
        }
        return nil
    }

    public func isNull() throws -> Bool {
        parser.isNull()
    }

    public var containerSize: Int {
        return -1
    }

}

private enum JSONDeserializerError: Error {
    case decodedNull
    case decodedEndList
    case decodedEndObject
}

private class DefaultDeserializer: ShapeDeserializer {

    func readStruct<T>(_ schema: Smithy.Schema, _ value: inout T) throws where T : SmithySerialization.DeserializableStruct {
        // no-op
    }
    
    func readList<E>(_ schema: Smithy.Schema, _ consumer: (any SmithySerialization.ShapeDeserializer) throws -> E) throws -> [E] {
        []
    }
    
    func readMap<V>(_ schema: Smithy.Schema, _ consumer: (any SmithySerialization.ShapeDeserializer) throws -> V) throws -> [String : V] {
        [:]
    }
    
    func readBoolean(_ schema: Smithy.Schema) throws -> Bool {
        false
    }
    
    func readBlob(_ schema: Smithy.Schema) throws -> Data {
        Data()
    }
    
    func readByte(_ schema: Smithy.Schema) throws -> Int8 {
        0
    }
    
    func readShort(_ schema: Smithy.Schema) throws -> Int16 {
        0
    }
    
    func readInteger(_ schema: Smithy.Schema) throws -> Int {
        0
    }
    
    func readLong(_ schema: Smithy.Schema) throws -> Int {
        0
    }
    
    func readFloat(_ schema: Smithy.Schema) throws -> Float {
        0.0
    }
    
    func readDouble(_ schema: Smithy.Schema) throws -> Double {
        0.0
    }
    
    func readBigInteger(_ schema: Smithy.Schema) throws -> Int64 {
        0
    }
    
    func readBigDecimal(_ schema: Smithy.Schema) throws -> Double {
        0.0
    }
    
    func readString(_ schema: Smithy.Schema) throws -> String {
        ""
    }
    
    func readDocument(_ schema: Smithy.Schema) throws -> Smithy.Document {
        throw DefaultDeserializerError.notImplemented
    }
    
    func readTimestamp(_ schema: Smithy.Schema) throws -> Date {
        Date(timeIntervalSince1970: 0.0)
    }
    
    func readNull<T>(_ schema: Smithy.Schema) throws -> T? {
        throw DefaultDeserializerError.notImplemented
    }
    
    func isNull() throws -> Bool {
        throw DefaultDeserializerError.notImplemented
    }
    
    var containerSize: Int { -1 }
}

enum DefaultDeserializerError: Error {
    case notImplemented
}
