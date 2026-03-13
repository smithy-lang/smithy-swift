//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import struct Smithy.Document
import struct Smithy.Schema
import protocol SmithySerialization.DeserializableStruct
import struct SmithySerialization.SerializerError
import protocol SmithySerialization.ShapeDeserializer

struct SDKUnknownDeserializer: ShapeDeserializer {
    let string: String

    init(string: String) {
        self.string = string
    }

    func readStruct<T>(_ schema: Schema, _ value: inout T) throws where T: DeserializableStruct {
        throw notImplemented
    }

    func readList<E>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> E) throws -> [E] {
        throw notImplemented
    }

    func readMap<V>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> V) throws -> [String: V] {
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

    func readInteger(_ schema: Schema) throws -> Int {
        throw notImplemented
    }

    func readLong(_ schema: Schema) throws -> Int {
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
        string
    }

    func readDocument(_ schema: Schema) throws -> Document {
        throw notImplemented
    }

    func readTimestamp(_ schema: Schema) throws -> Date {
        throw notImplemented
    }

    func readNull<T>(_ schema: Schema) throws -> T? {
        throw notImplemented
    }

    func isNull() throws -> Bool {
        throw notImplemented
    }

    var containerSize: Int { -1 }

    private var notImplemented: SerializerError { .init("Not implemented") }
}
