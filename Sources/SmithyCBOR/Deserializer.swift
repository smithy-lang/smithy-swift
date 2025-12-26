//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import class Smithy.Schema
@_spi(SmithyDocumentImpl) import struct Smithy.NullDocument
import protocol Smithy.SmithyDocument
import typealias SmithySerialization.ReadStructConsumer
import typealias SmithySerialization.ReadValueConsumer
import protocol SmithySerialization.DeserializableStruct
import protocol SmithySerialization.ShapeDeserializer

struct Deserializer: ShapeDeserializer {

    init() throws {
        
    }

    func readBoolean(_ schema: Smithy.Schema) throws -> Bool {
        false
    }
    
    func readBlob(_ schema: Smithy.Schema) throws -> Data {
        Data()
    }
    
    func readByte(_ schema: Smithy.Schema) throws -> UInt8 {
        0
    }
    
    func readShort(_ schema: Smithy.Schema) throws -> UInt16 {
        0
    }
    
    func readInteger(_ schema: Smithy.Schema) throws -> Int {
        0
    }
    
    func readLong(_ schema: Smithy.Schema) throws -> Int {
        0
    }
    
    func readFloat(_ schema: Smithy.Schema) throws -> Float {
        0.0
    }
    
    func readDouble(_ schema: Smithy.Schema) throws -> Double {
        0.0
    }
    
    func readBigInteger(_ schema: Smithy.Schema) throws -> Int64 {
        0
    }
    
    func readBigDecimal(_ schema: Smithy.Schema) throws -> Double {
        0.0
    }
    
    func readString(_ schema: Smithy.Schema) throws -> String {
        ""
    }
    
    func readDocument() throws -> any Smithy.SmithyDocument {
        NullDocument()
    }
    
    func readTimestamp(_ schema: Smithy.Schema) throws -> Date {
        Date()
    }
    
    func isNull() throws -> Bool {
        false
    }
    
    func readStruct<T: SmithySerialization.DeserializableStruct>(
        _ schema: Smithy.Schema,
        _ value: inout T
    ) throws {
        //
    }
    
    func readList<Element>(
        _ schema: Smithy.Schema,
        _ list: inout [Element],
        _ consumer: SmithySerialization.ReadValueConsumer<Element>
    ) throws {
        //
    }

    func readMap<Value>(
        _ schema: Smithy.Schema,
        _ map: inout [String : Value],
        _ consumer: SmithySerialization.ReadValueConsumer<Value>
    ) throws {
        //
    }

    var containerSize: Int = -1
}
