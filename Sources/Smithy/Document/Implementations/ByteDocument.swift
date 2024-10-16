//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyDocumentImpl)
public struct ByteDocument: SmithyDocument {
    public var type: ShapeType { .byte }
    let value: Int8

    public init(value: Int8) {
        self.value = value
    }

    public func asByte() throws -> Int8 {
        value
    }

    public func asShort() throws -> Int16 {
        Int16(value)
    }

    public func asInteger() throws -> Int {
        Int(value)
    }

    public func asLong() throws -> Int64 {
        Int64(value)
    }

    public func asFloat() throws -> Float {
        Float(value)
    }

    public func asDouble() throws -> Double {
        Double(value)
    }

    public func asBigInteger() throws -> Int64 {
        Int64(value)
    }

    public func asBigDecimal() throws -> Double {
        Double(value)
    }
}
