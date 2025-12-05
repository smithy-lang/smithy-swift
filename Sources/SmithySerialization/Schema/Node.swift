//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Contains the value of a Smithy Node.
///
/// Smithy node data is basically the same as the data that can be stored in JSON.
/// The root of a Smithy node may be of any type, i.e. unlike JSON, the root element is not limited to object or list.
///
/// See the definition of node value in the Smithy spec: https://smithy.io/2.0/spec/model.html#node-values
public enum Node: Sendable {
    case object([String: Node])
    case list([Node])
    case string(String)
    case number(Double)
    case boolean(Bool)
    case null
}

public extension Node {

    /// Returns the object dictionary if this Node is `.object`, else returns `nil`.
    var object: [String: Node]? {
        guard case .object(let value) = self else { return nil }
        return value
    }

    /// Returns the array of `Node` if this node is `.list`, else returns `nil`.
    var list: [Node]? {
        guard case .list(let value) = self else { return nil }
        return value
    }

    /// Returns the string if this node is `.string`, else returns `nil`.
    var string: String? {
        guard case .string(let value) = self else { return nil }
        return value
    }

    /// Returns the Double if this node is `.number`, else returns `nil`.
    var number: Double? {
        guard case .number(let value) = self else { return nil }
        return value
    }

    /// Returns the `Bool` value if this node is `.boolean`, else returns `nil`.
    var boolean: Bool? {
        guard case .boolean(let value) = self else { return nil }
        return value
    }

    /// Returns `true` if this node is `.null`, else returns `false`.
    var null: Bool {
        guard case .null = self else { return false }
        return true
    }
}

extension Node: ExpressibleByDictionaryLiteral {

    public init(dictionaryLiteral elements: (String, Node)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension Node: ExpressibleByArrayLiteral {

    public init(arrayLiteral elements: Node...) {
        self = .list(elements)
    }
}

extension Node: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension Node: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: IntegerLiteralType) {
        self = .number(Double(value))
    }
}

extension Node: ExpressibleByFloatLiteral {

    public init(floatLiteral value: FloatLiteralType) {
        self = .number(Double(value))
    }
}

extension Node: ExpressibleByBooleanLiteral {

    public init(booleanLiteral value: BooleanLiteralType) {
        self = .boolean(value)
    }
}

extension Node: ExpressibleByNilLiteral {

    public init(nilLiteral: ()) {
        self = .null
    }
}
