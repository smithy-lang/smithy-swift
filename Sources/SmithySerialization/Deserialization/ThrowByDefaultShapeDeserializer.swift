//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import enum Smithy.ByteStream
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import protocol Smithy.SmithyDocument

@_spi(SchemaBasedSerde)
public protocol ThrowByDefaultShapeDeserializer: ShapeDeserializer {}

public extension ThrowByDefaultShapeDeserializer {

    func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws {
        throw notImplemented
    }

    func readList<E>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> E) throws -> [E] {
        throw notImplemented
    }

    func readMap<V>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> V) throws -> [String : V] {
        throw notImplemented
    }

    func readBoolean(_ schema: Schema) throws -> Bool {
        throw notImplemented
    }

    func readBlob(_ schema: Schema) throws -> Data {
        throw notImplemented
    }

    func readByte(_ schema: Schema) throws -> Int8 {
        throw notImplemented
    }

    func readShort(_ schema: Schema) throws -> Int16 {
        throw notImplemented
    }

    func readInteger(_ schema: Schema) throws -> Int32 {
        throw notImplemented
    }

    func readLong(_ schema: Schema) throws -> Int64 {
        throw notImplemented
    }

    func readFloat(_ schema: Schema) throws -> Float {
        throw notImplemented
    }

    func readDouble(_ schema: Schema) throws -> Double {
        throw notImplemented
    }

    func readBigInteger(_ schema: Schema) throws -> Int64 {
        throw notImplemented
    }

    func readBigDecimal(_ schema: Schema) throws -> Double {
        throw notImplemented
    }

    func readString(_ schema: Schema) throws -> String {
        throw notImplemented
    }

    func readDocument(_ schema: Schema) throws -> any SmithyDocument {
        throw notImplemented
    }

    func readTimestamp(_ schema: Schema) throws -> Date {
        throw notImplemented
    }

    public func readDataStream(_ schema: Schema) throws -> ByteStream {
        throw notImplemented
    }

    public func readEventStream<E: DeserializableStruct>(_ schema: Schema) throws -> AsyncThrowingStream<E, any Error> {
        throw notImplemented
    }
}

private var notImplemented: SerializerError { .init("Not implemented") }
