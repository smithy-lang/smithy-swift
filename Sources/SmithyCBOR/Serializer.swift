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
//        try S.writeConsumer(value, self)
        encoder.encode(.indef_break)
    }
    
    public func writeList<Element>(_ schema: Smithy.Schema, _ value: [Element], _ consumer: (Element, any SmithySerialization.ShapeSerializer) throws -> Void) throws {
        print("writeList: \(schema.id)")
    }
    
    public func writeMap<Value>(_ schema: Smithy.Schema, _ value: [String : Value], _ consumer: (Value, any SmithySerialization.ShapeSerializer) throws -> Void) throws {
        print("writeMap: \(schema.id)")
    }
    
    public func writeBoolean(_ schema: Smithy.Schema, _ value: Bool) throws {
        print("writeBoolean: \(schema.id)")
    }
    
    public func writeByte(_ schema: Smithy.Schema, _ value: Int8) throws {
        print("writeByte: \(schema.id)")
    }
    
    public func writeShort(_ schema: Smithy.Schema, _ value: Int16) throws {
        print("writeShort: \(schema.id)")
    }
    
    public func writeInteger(_ schema: Smithy.Schema, _ value: Int) throws {
        print("writeInteger: \(schema.id)")
    }
    
    public func writeLong(_ schema: Smithy.Schema, _ value: Int) throws {
        print("writeLong: \(schema.id)")
    }
    
    public func writeFloat(_ schema: Smithy.Schema, _ value: Float) throws {
        print("writeFloat: \(schema.id)")
    }
    
    public func writeDouble(_ schema: Smithy.Schema, _ value: Double) throws {
        print("writeDouble: \(schema.id)")
    }
    
    public func writeBigInteger(_ schema: Smithy.Schema, _ value: Int64) throws {
        print("writeBigInteger: \(schema.id)")
    }
    
    public func writeBigDecimal(_ schema: Smithy.Schema, _ value: Double) throws {
        print("writeBigDecimal: \(schema.id)")
    }
    
    public func writeString(_ schema: Smithy.Schema, _ value: String) throws {
        print("writeString: \(schema.id)")
    }
    
    public func writeBlob(_ schema: Smithy.Schema, _ value: Data) throws {
        print("writeBlob: \(schema.id)")
    }
    
    public func writeTimestamp(_ schema: Smithy.Schema, _ value: Date) throws {
        print("writeTimestamp: \(schema.id)")
    }
    
    public func writeDocument(_ schema: Smithy.Schema, _ value: any Smithy.SmithyDocument) throws {
        print("writeDocument: \(schema.id)")
    }
    
    public func writeNull(_ schema: Smithy.Schema) throws {
        print("writeNull: \(schema.id)")
    }
    
    public var data: Data {
        Data(encoder.getEncoded())
    }
}
