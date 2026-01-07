//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import class Smithy.Schema
import protocol Smithy.SmithyDocument

public protocol ShapeDeserializer {
    func readBoolean(_ schema: Schema) throws -> Bool
    func readBlob(_ schema: Schema) throws -> Data
    func readByte(_ schema: Schema) throws -> Int8
    func readShort(_ schema: Schema) throws -> Int16
    func readInteger(_ schema: Schema) throws -> Int
    func readLong(_ schema: Schema) throws -> Int
    func readFloat(_ schema: Schema) throws -> Float
    func readDouble(_ schema: Schema) throws -> Double
    func readBigInteger(_ schema: Schema) throws -> Int64
    func readBigDecimal(_ schema: Schema) throws -> Double
    func readString(_ schema: Schema) throws -> String
    func readDocument() throws -> any SmithyDocument
    func readTimestamp(_ schema: Schema) throws -> Date

    // Used to implement parsing sparse lists and maps.
    func isNull() throws -> Bool
    func readNull<T>(_ schema: Schema) throws -> T?

    func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws

    func readList<E>(_ schema: Schema, _ list: inout [E], _ consumer: ReadValueConsumer<E>) throws

    func readMap<V>(_ schema: Schema, _ map: inout [String: V], _ consumer: ReadValueConsumer<V>) throws

    var containerSize: Int { get }
}

public extension ShapeDeserializer {

    func readEnum<Enum: RawRepresentable>(
        _ schema: Schema
    ) throws -> Enum where Enum.RawValue == String {
        try Enum(rawValue: readString(schema))!
    }

    func readIntEnum<IntEnum: RawRepresentable>(
        _ schema: Schema
    ) throws -> IntEnum where IntEnum.RawValue == Int {
        try IntEnum(rawValue: readInteger(schema))!
    }

    func readSparseList<Element>(
        _ schema: Schema,
        _ list: inout [Element?],
        _ consumer: ReadValueConsumer<Element>
    ) throws {
        try readList(schema, &list) { deserializer in
            if try deserializer.isNull() {
                return try deserializer.readNull(schema.resolveTarget.member)
            } else {
                return try consumer(deserializer)
            }
        }
    }

    func readSparseMap<Value>(
        _ schema: Schema,
        _ map: inout [String : Value?],
        _ consumer: ReadValueConsumer<Value>
    ) throws {
        try readMap(schema, &map) { deserializer in
            if try deserializer.isNull() {
                return try deserializer.readNull(schema.resolveTarget.value)
            } else {
                return try consumer(deserializer)
            }
        }
    }
}
