//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import enum Smithy.ByteStream
import struct Smithy.Document
import struct Smithy.Schema
import protocol Smithy.SmithyDocument

public protocol ShapeDeserializer {
    func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws
    func readList<E>(_ schema: Schema, _ consumer: ReadValueConsumer<E>) throws -> [E]
    func readMap<V>(_ schema: Schema, _ consumer: ReadValueConsumer<V>) throws -> [String: V]
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
    func readDocument(_ schema: Schema) throws -> Smithy.Document
    func readTimestamp(_ schema: Schema) throws -> Date
    func readNull<T>(_ schema: Schema) throws -> T?
    func readDataStream(_ schema: Schema) throws -> ByteStream
    func readEventStream<E: DeserializableStruct>(_ schema: Schema) throws -> AsyncThrowingStream<E, any Error>
    func isNull() throws -> Bool
    var containerSize: Int { get }
}

public extension ShapeDeserializer {

    func readEnum<T: RawRepresentable>(_ schema: Schema) throws -> T where T.RawValue == String {
        // Force-unwrap is safe here because generated enums & intEnums never return nil from init(rawValue:)
        try T(rawValue: readString(schema))!
    }

    func readIntEnum<T: RawRepresentable>(_ schema: Schema) throws -> T where T.RawValue == Int {
        // Force-unwrap is safe here because generated enums & intEnums never return nil from init(rawValue:)
        try T(rawValue: readInteger(schema))!
    }

    func readSparseList<E>(_ schema: Schema, _ consumer: ReadValueConsumer<E>) throws -> [E?] {
        try readList(schema) { deserializer in
            if try deserializer.isNull() {
                return try deserializer.readNull(schema.resolveTarget.member)
            } else {
                return try consumer(deserializer)
            }
        }
    }

    func readSparseMap<V>(_ schema: Schema, _ consumer: ReadValueConsumer<V>) throws -> [String: V?] {
        try readMap(schema) { deserializer in
            if try deserializer.isNull() {
                return try deserializer.readNull(schema.resolveTarget.value)
            } else {
                return try consumer(deserializer)
            }
        }
    }

    func readDataStream(_ schema: Schema) throws -> ByteStream {
        // by default, do nothing
        return ByteStream.data(nil)
    }

    func readEventStream<E: DeserializableStruct>(_ schema: Schema) throws -> AsyncThrowingStream<E, any Error> {
        // by default, do nothing
        return AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }
}
