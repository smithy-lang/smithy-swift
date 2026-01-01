//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit
import struct Foundation.Data
import struct Foundation.Date
@_spi(SmithyDocumentImpl) import struct Smithy.NullDocument
import class Smithy.Schema
import protocol Smithy.SmithyDocument
import protocol SmithySerialization.ShapeSerializer
import protocol SmithySerialization.SerializableStruct

public class Serializer: ShapeSerializer {
    let encoder: CBOREncoder

    public convenience init() throws {
        self.init(encoder: try CBOREncoder())
    }

    init(encoder: CBOREncoder) {
        self.encoder = encoder
    }

    public func writeStruct<S: SerializableStruct>(_ schema: Smithy.Schema, _ value: S) throws {
        print("writeStruct: \(schema.id)")
        encoder.encode(.indef_map_start)
        let members = schema.target?.members ?? schema.members
        for member in members {
            try S.writeConsumer(member, value, self)
        }
        encoder.encode(.indef_break)
    }
    
    public func writeList<Element>(_ schema: Smithy.Schema, _ value: [Element], _ consumer: (Element, any SmithySerialization.ShapeSerializer) throws -> Void) throws {
        print("writeList: \(schema.id)")
        encoder.encode(.indef_array_start)
        for element in value {
            try consumer(element, self)
        }
        encoder.encode(.indef_break)
    }
    
    public func writeMap<Value>(_ schema: Smithy.Schema, _ value: [String : Value], _ consumer: (Value, any SmithySerialization.ShapeSerializer) throws -> Void) throws {
        print("writeMap: \(schema.id)")
        encoder.encode(.indef_map_start)
        for (key, value) in value {
            encoder.encode(.text(key))
            try consumer(value, self)
        }
        encoder.encode(.indef_break)
    }
    
    public func writeBoolean(_ schema: Smithy.Schema, _ value: Bool) throws {
        print("writeBoolean: \(schema.id)")
        encoder.encode(.bool(value))
    }
    
    public func writeByte(_ schema: Smithy.Schema, _ value: Int8) throws {
        print("writeByte: \(schema.id)")
        encoder.encode(.int(Int64(value)))
    }
    
    public func writeShort(_ schema: Smithy.Schema, _ value: Int16) throws {
        print("writeShort: \(schema.id)")
        encoder.encode(.int(Int64(value)))
    }
    
    public func writeInteger(_ schema: Smithy.Schema, _ value: Int) throws {
        print("writeInteger: \(schema.id)")
        encoder.encode(.int(Int64(value)))
    }
    
    public func writeLong(_ schema: Smithy.Schema, _ value: Int) throws {
        print("writeLong: \(schema.id)")
        encoder.encode(.int(Int64(value)))
    }
    
    public func writeFloat(_ schema: Smithy.Schema, _ value: Float) throws {
        print("writeFloat: \(schema.id)")
        encoder.encode(.double(Double(value)))
    }
    
    public func writeDouble(_ schema: Smithy.Schema, _ value: Double) throws {
        print("writeDouble: \(schema.id)")
        encoder.encode(.double(value))
    }
    
    public func writeBigInteger(_ schema: Smithy.Schema, _ value: Int64) throws {
        print("writeBigInteger: \(schema.id)")
        encoder.encode(.int(value))
    }
    
    public func writeBigDecimal(_ schema: Smithy.Schema, _ value: Double) throws {
        print("writeBigDecimal: \(schema.id)")
        encoder.encode(.double(value))
    }
    
    public func writeString(_ schema: Smithy.Schema, _ value: String) throws {
        print("writeString: \(schema.id)")
        encoder.encode(.text(value))
    }
    
    public func writeBlob(_ schema: Smithy.Schema, _ value: Data) throws {
        print("writeBlob: \(schema.id)")
        encoder.encode(.bytes(value))
    }
    
    public func writeTimestamp(_ schema: Smithy.Schema, _ value: Date) throws {
        print("writeTimestamp: \(schema.id)")
        encoder.encode(.date(value))
    }
    
    public func writeNull(_ schema: Smithy.Schema) throws {
        print("writeNull: \(schema.id)")
        encoder.encode(.null)
    }
    
    public var data: Data {
        Data(encoder.getEncoded())
    }
}
