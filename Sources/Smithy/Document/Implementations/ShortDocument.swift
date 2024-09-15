//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyDocumentImpl)
public struct ShortDocument: Document {
    public var type: ShapeType { .short }
    let value: Int16

    public init(value: Int16) {
        self.value = value
    }

    public func asByte() throws -> Int8 {
        guard let byte = Int8(exactly: value) else {
            throw DocumentError.numberOverflow("Short \(value) overflows byte")
        }
        return byte
    }

    public func asShort() throws -> Int16 {
        value
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
