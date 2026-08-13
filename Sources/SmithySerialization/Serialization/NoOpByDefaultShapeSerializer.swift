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

/// Provides a basis for a ShapeSerializer that has a default, no-op implementation for every
/// ShapeSerializer method.
///
/// Useful for avoiding boilerplate code in special-purpose serializers, by only writing an implementation
/// for the specific method(s) you're implementing.
@_spi(SchemaBasedSerde)
public protocol NoOpByDefaultShapeSerializer: ShapeSerializer {}

public extension NoOpByDefaultShapeSerializer {

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        // no operation
    }

    public func writeList<E>(
        _ schema: Schema,
        _ value: [E],
        _ consumer: (E, any ShapeSerializer) throws -> Void
    ) throws {
        // no operation
    }

    public func writeMap<V>(
        _ schema: Schema,
        _ value: [String : V],
        _ consumer: (V, any ShapeSerializer) throws -> Void
    ) throws {
        // no operation
    }

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        // no operation
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        // no operation
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        // no operation
    }

    public func writeInteger(_ schema: Schema, _ value: Int32) throws {
        // no operation
    }

    public func writeLong(_ schema: Schema, _ value: Int64) throws {
        // no operation
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        // no operation
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        // no operation
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        // no operation
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        // no operation
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        // no operation
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        // no operation
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        // no operation
    }

    public func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws {
        // no operation
    }

    public func writeDataStream(_ schema: Schema, _ value: ByteStream) throws {
        // no operation
    }

    public func writeEventStream<E: SerializableStruct & Sendable>(
        _ schema: Schema,
        _ value: AsyncThrowingStream<E, any Error>
    ) throws {
        // no operation
    }

    public func writeNull(_ schema: Schema) throws {
        // no operation
    }

    public var data: Data { Data() }
}
