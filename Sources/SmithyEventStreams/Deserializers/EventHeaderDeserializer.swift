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
import struct SmithyEventStreamsAPI.Header
import protocol SmithySerialization.DeserializableStruct
import struct SmithySerialization.SerializerError
import protocol SmithySerialization.ShapeDeserializer

/// A deserializer for event stream data that is bound to event headers.
///
/// Only use for deserializing event headers.  Deserializing a type that cannot be bound to an event
/// header will throw a "not implemented" error.
struct EventHeaderDeserializer: ShapeDeserializer {
    let header: Header

    init(header: Header) {
        self.header = header
    }

    func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws {
        throw notImplemented
    }

    func readList<E>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> E) throws -> [E] {
        throw notImplemented
    }

    func readMap<V>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> V) throws -> [String: V] {
        throw notImplemented
    }

    func readBoolean(_ schema: Schema) throws -> Bool {
        guard case .bool(let value) = header.value else {
            throw SerializerError("Expected bool header value for \(schema.id), got \(header.value.type)")
        }
        return value
    }

    func readBlob(_ schema: Schema) throws -> Data {
        guard case .byteArray(let value) = header.value else {
            throw SerializerError("Expected byteArray header value for \(schema.id), got \(header.value.type)")
        }
        return value
    }

    func readByte(_ schema: Schema) throws -> Int8 {
        switch header.value {
        case .byte(let value):
            return value
        case .int16(let int16):
            guard int16 <= Int8.max && int16 >= Int8.min else {
                throw SerializerError("Int16 overflows Int8.  Value: \(int16)")
            }
            return Int8(int16)
        case .int32(let int32):
            guard int32 <= Int8.max && int32 >= Int8.min else {
                throw SerializerError("Int32 overflows Int8.  Value: \(int32)")
            }
            return Int8(int32)
        case .int64(let int64):
            guard int64 <= Int8.max && int64 >= Int8.min else {
                throw SerializerError("Int64 overflows Int8.  Value: \(int64)")
            }
            return Int8(int64)
        default:
            throw SerializerError("Cannot convert headerValue \(header.value.type) to byte")
        }
    }

    func readShort(_ schema: Schema) throws -> Int16 {
        switch header.value {
        case .byte(let byte):
            return Int16(byte)
        case .int16(let value):
            return value
        case .int32(let int32):
            guard int32 <= Int16.max && int32 >= Int16.min else {
                throw SerializerError("Int32 overflows Int16.  Value: \(int32)")
            }
            return Int16(int32)
        case .int64(let int64):
            guard int64 <= Int16.max && int64 >= Int16.min else {
                throw SerializerError("Int64 overflows Int16.  Value: \(int64)")
            }
            return Int16(int64)
        default:
            throw SerializerError("Cannot convert headerValue \(header.value.type) to byte")
        }
    }

    func readInteger(_ schema: Schema) throws -> Int {
        switch header.value {
        case .byte(let byte):
            return Int(byte)
        case .int16(let int16):
            return Int(int16)
        case .int32(let value):
            return Int(value)
        case .int64(let int64):
            guard int64 <= Int.max && int64 >= Int.min else {
                throw SerializerError("Int64 overflows Int.  Value: \(int64)")
            }
            return Int(int64)
        default:
            throw SerializerError("Cannot convert headerValue \(header.value.type) to byte")
        }
    }

    func readLong(_ schema: Schema) throws -> Int {
        switch header.value {
        case .byte(let byte):
            return Int(byte)
        case .int16(let int16):
            return Int(int16)
        case .int32(let value):
            return Int(value)
        case .int64(let int64):
            guard int64 <= Int.max && int64 >= Int.min else {
                throw SerializerError("Int64 overflows Int.  Value: \(int64)")
            }
            return Int(int64)
        default:
            throw SerializerError("Cannot convert headerValue \(header.value.type) to byte")
        }
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
        guard case .string(let value) = header.value else {
            throw SerializerError("Expected string header value for \(schema.id), got \(header.value.type)")
        }
        return value
    }

    func readDocument(_ schema: Schema) throws -> Smithy.Document {
        throw notImplemented
    }

    func readTimestamp(_ schema: Schema) throws -> Date {
        guard case .timestamp(let value) = header.value else {
            throw SerializerError("Expected timestamp header value for \(schema.id), got \(header.value.type)")
        }
        return value
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
