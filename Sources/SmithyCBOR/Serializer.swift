//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class AwsCommonRuntimeKit.CBOREncoder
import struct Foundation.Data
import struct Foundation.Date
import class Smithy.Schema
import protocol SmithySerialization.SerializableStruct
import protocol SmithySerialization.ShapeSerializer
import typealias SmithySerialization.WriteValueConsumer

public final class Serializer: ShapeSerializer {
    let member: String?
    let encoder: CBOREncoder

    public convenience init() throws {
        self.init(member: nil, encoder: try CBOREncoder())
    }

    required init(member: String?, encoder: CBOREncoder) {
        self.member = member
        self.encoder = encoder
    }

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        writeMember()
        encoder.encode(.indef_map_start)
        let members = schema.target?.members ?? schema.members
        for member in members {
            let memberEncoder = Self(member: member.id.member, encoder: encoder)
            try S.writeConsumer(member, value, memberEncoder)
        }
        encoder.encode(.indef_break)
    }

    public func writeList<E>(_ schema: Schema, _ value: [E], _ consumer: WriteValueConsumer<E>) throws {
        writeMember()
        encoder.encode(.array_start(value.count))
        for element in value {
            let elementEncoder = Self(member: nil, encoder: encoder)
            try consumer(element, elementEncoder)
        }
    }

    public func writeMap<V>(_ schema: Schema, _ value: [String: V], _ consumer: WriteValueConsumer<V>) throws {
        writeMember()
        encoder.encode(.map_start(value.count))
        for (key, value) in value {
            encoder.encode(.text(key))
            let valueEncoder = Self(member: nil, encoder: encoder)
            try consumer(value, valueEncoder)
        }
    }

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        writeMember()
        encoder.encode(.bool(value))
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        writeMember()
        encoder.encode(.int(Int64(value)))
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        writeMember()
        encoder.encode(.int(Int64(value)))
    }

    public func writeInteger(_ schema: Schema, _ value: Int) throws {
        writeMember()
        encoder.encode(.int(Int64(value)))
    }

    public func writeLong(_ schema: Schema, _ value: Int) throws {
        writeMember()
        encoder.encode(.int(Int64(value)))
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        writeMember()
        encoder.encode(.double(Double(value)))
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        writeMember()
        encoder.encode(.double(value))
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        writeMember()
        encoder.encode(.int(value))
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        writeMember()
        encoder.encode(.double(value))
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        writeMember()
        encoder.encode(.text(value))
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        writeMember()
        encoder.encode(.bytes(value))
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        writeMember()
        encoder.encode(.date(value))
    }

    public func writeNull(_ schema: Schema) throws {
        writeMember()
        encoder.encode(.null)
    }

    public var data: Data {
        Data(encoder.getEncoded())
    }

    private func writeMember() {
        guard let member else { return }
        encoder.encode(.text(member))
    }
}
