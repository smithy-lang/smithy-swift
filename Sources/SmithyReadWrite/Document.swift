//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum Document {
    case array([Document])
    case boolean(Bool)
    case number(Double)
    case object([String: Document])
    case string(String)
    case null
}

extension Document: Equatable { }

extension Document: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Document...) {
        self = .array(elements)
    }
}

extension Document: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .boolean(value)
    }
}

extension Document: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Document)...) {
        let dictionary = elements.reduce([String: Document]()) { acc, curr in
            var newValue = acc
            newValue[curr.0] = curr.1
            return newValue
        }
        self = .object(dictionary)
    }
}

extension Document: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension Document: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension Document: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension Document: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

// extension to use subscribts to get the values from objects/arrays as normal
public extension Document {

    subscript(_ key: String) -> Document? {
        guard case .object(let object) = self else {
            return nil
        }
        return object[key]
    }

    subscript(_ key: Int) -> Document? {
        switch self {
        case .array(let array):
            return array[key]
        case .object(let object):
            return object["\(key)"]
        default:
            return nil
        }
    }
}
