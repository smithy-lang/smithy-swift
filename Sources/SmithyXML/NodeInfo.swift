//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct NodeInfo: Equatable {

    public enum Location {
        case element
        case attribute
    }

    public struct Namespace: Equatable {
        let prefix: String
        let uri: String

        public init(prefix: String, uri: String) {
            self.prefix = prefix
            self.uri = uri
        }
    }

    public var prefix: String? {
        namespace?.prefix ?? _prefix
    }

    /// The namespace prefix parsed from the name of this node, if any.
    private let _prefix: String

    /// The name for this XML node, with its namespace removed.
    public let name: String

    /// The location for this XML node.
    ///
    /// Supported locations are `element` and `attribute`.  XML nodes for other locations are ignored.
    public let location: Location

    /// The XML namespace that applies to this node, if any.
    public let namespaceDef: Namespace?

    /// The XML namespace that is defined on this XML node.
    public let namespace: Namespace?

    public init(
        _ name: String,
        location: Location = .element,
        namespaceDef: Namespace? = nil,
        namespace: Namespace? = nil
    ) {
        let (prefix, baseName) = Self.components(from: name)
        self._prefix = prefix
        self.name = baseName
        self.location = location
        self.namespaceDef = namespaceDef
        self.namespace = namespace
    }

    private static func components(from name: String) -> (String, String) {
        let components = name.split(separator: ":")
        if components.count == 2 {
            return (String(components[0]), String(components[1]))
        } else {
            return ("", name)
        }
    }
}

extension NodeInfo: ExpressibleByStringLiteral {

    public typealias StringLiteralType = String

    /// Creates a new `NodeInfo` with the string literal as name, location of `.element`, and `nil` namespace & namespaceDef.
    /// - Parameter value: The name for the `NodeInfo`.
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension NodeInfo: CustomStringConvertible {

    /// When converted to string, `NodeInfo` returns its name.
    public var description: String { name }
}

public extension NodeInfo {
    
    /// Compares a `NodeInfo`'s `name` to a string.
    /// - Parameters:
    ///   - lhs: The `NodeInfo` to be compared
    ///   - rhs: The string to be compared.
    /// - Returns: `true` if the `NodeInfo`'s `name` is equal to the string, `false` otherwise.
    static func ==(lhs: NodeInfo, rhs: String) -> Bool {
        return lhs.name == rhs
    }

    /// Compares a `NodeInfo`'s `name` to a string.
    /// - Parameters:
    ///   - lhs: The string to be compared.
    ///   - rhs: The `NodeInfo` to be compared
    /// - Returns: `true` if the `NodeInfo`'s `name` is equal to the string, `false` otherwise.
    static func ==(lhs: String, rhs: NodeInfo) -> Bool {
        return lhs == rhs.name
    }
}
