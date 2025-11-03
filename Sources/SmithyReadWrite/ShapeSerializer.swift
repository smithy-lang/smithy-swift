//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.TimeInterval
import class Smithy.Schema
import protocol Smithy.SmithyDocument
import protocol Smithy.ReadableStream

public protocol ShapeSerializer {
    func writeStruct(schema: Schema, struct: SerializableStruct)
    func writeList(schema: Schema, size: Int, consumer: Consumer<ShapeSerializer>)
    func writeMap(schema: Schema, size: Int, consumer: Consumer<MapSerializer>)
    func writeBoolean(schema: Schema, value: Bool)
    func writeByte(schema: Schema, value: Int8)
    func writeShort(schema: Schema, value: Int16)
    func writeInteger(schema: Schema, value: Int)
    func writeLong(schema: Schema, value: Int64)
    func writeFloat(schema: Schema, value: Float)
    func writeDouble(schema: Schema, value: Double)
    func writeBigInteger(schema: Schema, value: Int64)
    func writeBigDecimal(schema: Schema, value: Double)
    func writeString(schema: Schema, value: String)
    func writeBlob(schema: Schema, value: Data)
    func writeTimestamp(schema: Schema, value: TimeInterval)
    func writeDocument(schema: Schema, value: any SmithyDocument)
    func writeNull(schema: Schema)

//    func writeDataStream(schema: Schema, value: any ReadableStream)
//    func writeEventStream<T: SerializableStruct>(schema: Schema, value: Flow.Publisher<T>)
}
