//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class AwsCommonRuntimeKit.CBOREncoder
import struct Foundation.Data
import struct Foundation.Date
import struct Smithy.Schema
import protocol Smithy.SmithyDocument
import protocol SmithySerialization.SerializableStruct
import struct SmithySerialization.SerializerError
import protocol SmithySerialization.ShapeSerializer
import typealias SmithySerialization.WriteValueConsumer

public final class Serializer: ShapeSerializer {
    let encoder: CBOREncoder

    public init() throws {
        self.encoder = try CBOREncoder()
    }

    // MARK: - ShapeSerializer conformance

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        writeMember(schema: schema)
        encoder.encode(.indef_map_start)
        for member in schema.members {
            try S.writeConsumer(member, value, self)
        }
        encoder.encode(.indef_break)
    }

    public func writeList<E>(_ schema: Schema, _ value: [E], _ consumer: WriteValueConsumer<E>) throws {
        writeMember(schema: schema)
        encoder.encode(.array_start(value.count))
        for element in value {
            try consumer(element, self)
        }
    }

    public func writeMap<V>(_ schema: Schema, _ value: [String: V], _ consumer: WriteValueConsumer<V>) throws {
        writeMember(schema: schema)
        encoder.encode(.map_start(value.count))
        for (key, value) in value {
            encoder.encode(.text(key))
            try consumer(value, self)
        }
    }

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        writeMember(schema: schema)
        encoder.encode(.bool(value))
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        writeMember(schema: schema)
        encoder.encode(.int(Int64(value)))
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        writeMember(schema: schema)
        encoder.encode(.int(Int64(value)))
    }

    public func writeInteger(_ schema: Schema, _ value: Int) throws {
        writeMember(schema: schema)
        encoder.encode(.int(Int64(value)))
    }

    public func writeLong(_ schema: Schema, _ value: Int) throws {
        writeMember(schema: schema)
        encoder.encode(.int(Int64(value)))
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        writeMember(schema: schema)
        encoder.encode(.double(Double(value)))
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        writeMember(schema: schema)
        encoder.encode(.double(value))
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        writeMember(schema: schema)
        encoder.encode(.int(value))
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        writeMember(schema: schema)
        encoder.encode(.double(value))
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        writeMember(schema: schema)
        encoder.encode(.text(value))
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        writeMember(schema: schema)
        encoder.encode(.bytes(value))
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        writeMember(schema: schema)
        encoder.encode(.date(value))
    }

    public func writeNull(_ schema: Schema) throws {
        writeMember(schema: schema)
        encoder.encode(.null)
    }

    public func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws {
        throw SerializerError("Document type not implemented in CBOR")
    }

    public var data: Data {
        Data(encoder.getEncoded())
    }

    // MARK: - Private methods

    private func writeMember(schema: Schema) {
        guard let memberName = schema.memberName else { return }
        encoder.encode(.text(memberName))
    }
}
