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
    func writeStruct(_ schema: Schema, _ value: any SerializableStruct) throws
    func writeList(_ schema: Schema, _ size: Int, _ consumer: Consumer<ShapeSerializer>) throws
    func writeMap(_ schema: Schema, _ size: Int, _ consumer: Consumer<MapSerializer>) throws
    func writeBoolean(_ schema: Schema, _ value: Bool) throws
    func writeByte(_ schema: Schema, _ value: Int8) throws
    func writeShort(_ schema: Schema, _ value: Int16) throws
    func writeInteger(_ schema: Schema, _ value: Int) throws
    func writeLong(_ schema: Schema, _ value: Int) throws
    func writeFloat(_ schema: Schema, _ value: Float) throws
    func writeDouble(_ schema: Schema, _ value: Double) throws
    func writeBigInteger(_ schema: Schema, _ value: Int64) throws
    func writeBigDecimal(_ schema: Schema, _ value: Double) throws
    func writeString(_ schema: Schema, _ value: String) throws
    func writeBlob(_ schema: Schema, _ value: Data) throws
    func writeTimestamp(_ schema: Schema, _ value: Date) throws
    func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws
    func writeNull(_ schema: Schema) throws
    func writeDataStream(_ schema: Schema, _ value: ByteStream) throws
    func writeEventStream(_ schema: Schema, _ value: AsyncThrowingStream<any SerializableStruct, any Error>) throws
}

public extension ShapeSerializer {

    func writeString<T: RawRepresentable>(_ schema: Schema, _ value: T) throws where T.RawValue == String {
        try writeString(schema, value.rawValue)
    }

    func writeInteger<T: RawRepresentable>(_ schema: Schema, _ value: T) throws where T.RawValue == Int {
        try writeInteger(schema, value.rawValue)
    }

    func writeDataStream(_ schema: Schema, _ value: ByteStream) throws {
        // by default, do nothing
    }

    func writeEventStream(_ schema: Schema, _ value: AsyncThrowingStream<any SerializableStruct, any Error>) throws {
        // by default, do nothing
    }
}
