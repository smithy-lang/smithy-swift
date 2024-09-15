//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyDocumentImpl)
public struct FloatDocument: SmithyDocument {
    public var type: ShapeType { .float }
    let value: Float

    public init(value: Float) {
        self.value = value
    }

    public func asByte() throws -> Int8 {
        guard let byte = Int8(exactly: value) else {
            throw DocumentError.numberOverflow("Float \(value) overflows byte")
        }
        return byte
    }

    public func asShort() throws -> Int16 {
        guard let short = Int16(exactly: value) else {
            throw DocumentError.numberOverflow("Float \(value) overflows short")
        }
        return short
    }

    public func asInteger() throws -> Int {
        guard let int = Int(exactly: value) else {
            throw DocumentError.numberOverflow("Float \(value) overflows int")
        }
        return int
    }

    public func asLong() throws -> Int64 {
        guard let long = Int64(exactly: value) else {
            throw DocumentError.numberOverflow("Float \(value) overflows long")
        }
        return long
    }

    public func asFloat() throws -> Float {
        value
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
