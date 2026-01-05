//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit
import struct Foundation.Data
import struct Foundation.Date
import class Smithy.Schema
import protocol SmithySerialization.ShapeSerializer
import protocol SmithySerialization.SerializableStruct

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

    public func writeStruct<S: SerializableStruct>(_ schema: Smithy.Schema, _ value: S) throws {
        writeMember()
        encoder.encode(.indef_map_start)
        print(".indef_map_start (struct \(schema.id))")
        let members = schema.target?.members ?? schema.members
        for member in members {
            let memberEncoder = Self(member: member.id.member, encoder: encoder)
            try S.writeConsumer(member, value, memberEncoder)
        }
        encoder.encode(.indef_break)
        print(".indef_break (struct \(schema.id))")
    }
    
    public func writeList<Element>(_ schema: Smithy.Schema, _ value: [Element], _ consumer: (Element, any SmithySerialization.ShapeSerializer) throws -> Void) throws {
        writeMember()
        encoder.encode(.indef_array_start)
        print(".indef_array_start (list \(schema.id))")
        for element in value {
            let elementEncoder = Self(member: nil, encoder: encoder)
            try consumer(element, elementEncoder)
        }
        encoder.encode(.indef_break)
        print(".indef_break (list \(schema.id))")
    }
    
    public func writeMap<Value>(_ schema: Smithy.Schema, _ value: [String : Value], _ consumer: (Value, any SmithySerialization.ShapeSerializer) throws -> Void) throws {
        writeMember()
        encoder.encode(.indef_map_start)
        print(".indef_map_start (map \(schema.id))")
        for (key, value) in value {
            encoder.encode(.text(key))
            print(".text() (map key: \(key))")
            let valueEncoder = Self(member: nil, encoder: encoder)
            try consumer(value, valueEncoder)
        }
        encoder.encode(.indef_break)
        print(".indef_break (map \(schema.id))")
    }
    
    public func writeBoolean(_ schema: Smithy.Schema, _ value: Bool) throws {
        writeMember()
        print("writeBoolean: \(schema.id)")
        encoder.encode(.bool(value))
        print(".bool()")
    }
    
    public func writeByte(_ schema: Smithy.Schema, _ value: Int8) throws {
        writeMember()
        print("writeByte: \(schema.id)")
        encoder.encode(.int(Int64(value)))
        print(".int()")
    }
    
    public func writeShort(_ schema: Smithy.Schema, _ value: Int16) throws {
        writeMember()
        print("writeShort: \(schema.id)")
        encoder.encode(.int(Int64(value)))
        print(".int()")
    }
    
    public func writeInteger(_ schema: Smithy.Schema, _ value: Int) throws {
        writeMember()
        print("writeInteger: \(schema.id)")
        encoder.encode(.int(Int64(value)))
        print(".int()")
    }
    
    public func writeLong(_ schema: Smithy.Schema, _ value: Int) throws {
        writeMember()
        print("writeLong: \(schema.id)")
        encoder.encode(.int(Int64(value)))
        print(".int()")
    }
    
    public func writeFloat(_ schema: Smithy.Schema, _ value: Float) throws {
        writeMember()
        print("writeFloat: \(schema.id)")
        encoder.encode(.double(Double(value)))
        print(".double()")
    }
    
    public func writeDouble(_ schema: Smithy.Schema, _ value: Double) throws {
        writeMember()
        print("writeDouble: \(schema.id)")
        encoder.encode(.double(value))
        print(".double()")
    }
    
    public func writeBigInteger(_ schema: Smithy.Schema, _ value: Int64) throws {
        writeMember()
        print("writeBigInteger: \(schema.id)")
        encoder.encode(.int(value))
        print(".int()")
    }
    
    public func writeBigDecimal(_ schema: Smithy.Schema, _ value: Double) throws {
        writeMember()
        print("writeBigDecimal: \(schema.id)")
        encoder.encode(.double(value))
        print(".double()")
    }
    
    public func writeString(_ schema: Smithy.Schema, _ value: String) throws {
        writeMember()
        print("writeString: \(schema.id)")
        encoder.encode(.text(value))
        print(".text() (string)")
    }
    
    public func writeBlob(_ schema: Smithy.Schema, _ value: Data) throws {
        print("writeBlob: \(schema.id)")
        writeMember()
        encoder.encode(.bytes(value))
        print(".bytes()")
    }
    
    public func writeTimestamp(_ schema: Smithy.Schema, _ value: Date) throws {
        print("writeTimestamp: \(schema.id)")
        writeMember()
        encoder.encode(.date(value))
        print(".date()")
    }
    
    public func writeNull(_ schema: Smithy.Schema) throws {
        print("writeNull: \(schema.id)")
        writeMember()
        encoder.encode(.null)
        print(".null")
    }
    
    public var data: Data {
        Data(encoder.getEncoded())
    }

    private func writeMember() {
        guard let member else { return }
        encoder.encode(.text(member))
        print(".text() (member: \(member))")
    }
}
