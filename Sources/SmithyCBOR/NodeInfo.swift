//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct NodeInfo: Equatable, Comparable {
    /// The name for this CBOR node, or an empty string if none.
    public let name: String

    public init(_ name: String) {
        self.name = name
    }

    public static func < (lhs: NodeInfo, rhs: NodeInfo) -> Bool {
        return lhs.name < rhs.name
    }
}

extension NodeInfo: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public init(stringLiteral value: String) {
        self.init(value)
    }
}
