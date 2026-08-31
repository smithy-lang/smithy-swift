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
import protocol Smithy.SmithyDocument
@_spi(SmithyDocumentImpl)
import struct Smithy.StringMapDocument

/// Provides a last-ditch default value suitable for filling in the value of a `@required` member
/// that was not sent by the server.
///
/// Not all of these methods may actually be utilized.
@_spi(SchemaBasedSerde)
public class DefaultValueDeserializer: ShapeDeserializer {

    public init() {}

    public func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws {
        // no operation, `value` is left as-is
    }

    public func readList<E>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> E) throws -> [E] {
        []
    }

    public func readMap<V>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> V) throws -> [String: V] {
        [:]
    }

    public func readBoolean(_ schema: Schema) throws -> Bool {
        false
    }

    public func readBlob(_ schema: Schema) throws -> Data {
        Data()
    }

    public func readByte(_ schema: Schema) throws -> Int8 {
        0
    }

    public func readShort(_ schema: Schema) throws -> Int16 {
        0
    }

    public func readInteger(_ schema: Schema) throws -> Int32 {
        0
    }

    public func readLong(_ schema: Schema) throws -> Int64 {
        0
    }

    public func readFloat(_ schema: Schema) throws -> Float {
        0.0
    }

    public func readDouble(_ schema: Schema) throws -> Double {
        0.0
    }

    public func readBigInteger(_ schema: Schema) throws -> Int64 {
        0
    }

    public func readBigDecimal(_ schema: Schema) throws -> Double {
        0.0
    }

    public func readString(_ schema: Schema) throws -> String {
        ""
    }

    public func readDocument(_ schema: Schema) throws -> any SmithyDocument {
        StringMapDocument(value: [:])
    }

    public func readTimestamp(_ schema: Schema) throws -> Date {
        Date(timeIntervalSince1970: 0.0)
    }

    public var mediaType: String? { nil }
}
