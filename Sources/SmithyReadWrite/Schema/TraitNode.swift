//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum TraitNode: Sendable {
    case object([String: TraitNode])
    case list([TraitNode])
    case string(String)
    case number(Double)
    case boolean(Bool)
    case null
}

extension TraitNode: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = TraitNode

    public init(dictionaryLiteral elements: (String, TraitNode)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension TraitNode: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = TraitNode

    public init(arrayLiteral elements: TraitNode...) {
        self = .list(elements)
    }
}

extension TraitNode: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension TraitNode: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: IntegerLiteralType) {
        self = .number(Double(value))
    }
}

extension TraitNode: ExpressibleByFloatLiteral {

    public init(floatLiteral value: FloatLiteralType) {
        self = .number(Double(value))
    }
}

extension TraitNode: ExpressibleByBooleanLiteral {

    public init(booleanLiteral value: BooleanLiteralType) {
        self = .boolean(value)
    }
}

extension TraitNode: ExpressibleByNilLiteral {

    public init(nilLiteral: ()) {
        self = .null
    }
}
