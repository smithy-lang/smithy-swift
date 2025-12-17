//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import enum Smithy.ByteStream
import protocol Smithy.SmithyDocument
import class Smithy.Schema

public protocol ShapeSerializer {
    func writeStruct(schema: Schema, value: any SerializableStruct)
    func writeList(schema: Schema, size: Int, consumer: Consumer<ShapeSerializer>)
    func writeMap(schema: Schema, size: Int, consumer: Consumer<MapSerializer>)
    func writeBoolean(schema: Schema, value: Bool)
    func writeByte(schema: Schema, value: Int8)
    func writeShort(schema: Schema, value: Int16)
    func writeInteger(schema: Schema, value: Int)
    func writeLong(schema: Schema, value: Int)
    func writeFloat(schema: Schema, value: Float)
    func writeDouble(schema: Schema, value: Double)
    func writeBigInteger(schema: Schema, value: Int64)
    func writeBigDecimal(schema: Schema, value: Double)
    func writeString(schema: Schema, value: String)
    func writeBlob(schema: Schema, value: Data)
    func writeTimestamp(schema: Schema, value: Date)
    func writeDocument(schema: Schema, value: any SmithyDocument)
    func writeNull(schema: Schema)
    func writeDataStream(schema: Schema, value: ByteStream)
    func writeEventStream(schema: Schema, value: AsyncThrowingStream<any SerializableStruct, any Error>)
}

public extension ShapeSerializer {
    
    func writeString<T: RawRepresentable>(schema: Schema, value: T) where T.RawValue == String {
        writeString(schema: schema, value: value.rawValue)
    }

    func writeInteger<T: RawRepresentable>(schema: Schema, value: T) where T.RawValue == Int {
        writeInteger(schema: schema, value: value.rawValue)
    }

    func writeDataStream(schema: Schema, value: ByteStream) {
        // by default, do nothing
    }

    func writeEventStream(schema: Schema, value: AsyncThrowingStream<any SerializableStruct, any Error>) {
        // by default, do nothing
    }
}
