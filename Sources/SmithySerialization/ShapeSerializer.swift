//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import enum Smithy.ByteStream
import class Smithy.Schema
import protocol Smithy.SmithyDocument

public protocol ShapeSerializer {
    func writeStruct(schema: Schema, value: any SerializableStruct) throws
    func writeList(schema: Schema, size: Int, consumer: Consumer<ShapeSerializer>) throws
    func writeMap(schema: Schema, size: Int, consumer: Consumer<MapSerializer>) throws
    func writeBoolean(schema: Schema, value: Bool) throws
    func writeByte(schema: Schema, value: Int8) throws
    func writeShort(schema: Schema, value: Int16) throws
    func writeInteger(schema: Schema, value: Int) throws
    func writeLong(schema: Schema, value: Int) throws
    func writeFloat(schema: Schema, value: Float) throws
    func writeDouble(schema: Schema, value: Double) throws
    func writeBigInteger(schema: Schema, value: Int64) throws
    func writeBigDecimal(schema: Schema, value: Double) throws
    func writeString(schema: Schema, value: String) throws
    func writeBlob(schema: Schema, value: Data) throws
    func writeTimestamp(schema: Schema, value: Date) throws
    func writeDocument(schema: Schema, value: any SmithyDocument) throws
    func writeNull(schema: Schema) throws
    func writeDataStream(schema: Schema, value: ByteStream) throws
    func writeEventStream(schema: Schema, value: AsyncThrowingStream<any SerializableStruct, any Error>) throws
}

public extension ShapeSerializer {

    func writeString<T: RawRepresentable>(schema: Schema, value: T) throws where T.RawValue == String {
        try writeString(schema: schema, value: value.rawValue)
    }

    func writeInteger<T: RawRepresentable>(schema: Schema, value: T) throws where T.RawValue == Int {
        try writeInteger(schema: schema, value: value.rawValue)
    }

    func writeDataStream(schema: Schema, value: ByteStream) throws {
        // by default, do nothing
    }

    func writeEventStream(schema: Schema, value: AsyncThrowingStream<any SerializableStruct, any Error>) throws {
        // by default, do nothing
    }
}
