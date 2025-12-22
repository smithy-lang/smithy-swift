//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import class Smithy.Schema
import protocol Smithy.SmithyDocument

public protocol ShapeDeserializer {
    func readBoolean(_ schema: Smithy.Schema) throws -> Bool
    func readBlob(_ schema: Smithy.Schema) throws -> Data
    func readByte(_ schema: Smithy.Schema) throws -> UInt8
    func readShort(_ schema: Smithy.Schema) throws -> UInt16
    func readInteger(_ schema: Smithy.Schema) throws -> Int
    func readLong(_ schema: Smithy.Schema) throws -> Int
    func readFloat(_ schema: Smithy.Schema) throws -> Float
    func readDouble(_ schema: Smithy.Schema) throws -> Double
    func readBigInteger(_ schema: Smithy.Schema) throws -> Int64
    func readBigDecimal(_ schema: Smithy.Schema) throws -> Double
    func readString(_ schema: Smithy.Schema) throws -> String
    func readDocument() throws -> any Smithy.SmithyDocument
    func readTimestamp(_ schema: Smithy.Schema) throws -> Date

    // Used to implement parsing sparse lists and maps.
    func isNull() throws -> Bool

    func readStruct(_ schema: Smithy.Schema, _ consumer: StructMemberConsumer) throws
    func readList<Element>(_ schema: Smithy.Schema, _ list: inout [Element], _ consumer: ListMemberConsumer<Element>) throws
    func readMap<Value>(_ schema: Smithy.Schema, _ map: inout [String: Value], _ consumer: MapMemberConsumer<String, Value>) throws

    var containerSize: Int { get }
}

public extension ShapeDeserializer {

    func readNull<T>() throws -> T? {
        return nil
    }


    func readEnum<Enum: RawRepresentable>(_ schema: Smithy.Schema) throws -> Enum where Enum.RawValue == String {
        try Enum(rawValue: readString(schema))!
    }

    func readIntEnum<Enum: RawRepresentable>(_ schema: Smithy.Schema) throws -> Enum where Enum.RawValue == Int {
        try Enum(rawValue: readInteger(schema))!
    }
}
