//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyDocumentImpl)
public struct IntegerDocument: Document {
    public var type: ShapeType { .integer }
    let value: Int

    public init(value: Int) {
        self.value = value
    }

    public func asByte() throws -> Int8 {
        guard let byte = Int8(exactly: value) else {
            throw DocumentError.numberOverflow("Int \(value) overflows byte")
        }
        return byte
    }

    public func asShort() throws -> Int16 {
        guard let short = Int16(exactly: value) else {
            throw DocumentError.numberOverflow("Int \(value) overflows short")
        }
        return short
    }

    public func asInteger() throws -> Int {
        value
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
