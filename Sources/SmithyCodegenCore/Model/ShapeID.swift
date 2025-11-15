//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Represents a Smithy shape ID.
///
/// The id that ShapeID is created from is presumed to be properly formed, since this type will usually
/// be constructed from previously validated models.
///
/// Shape ID is described in the Smithy 2.0 spec [here](https://smithy.io/2.0/spec/model.html#shape-id).
public struct ShapeID: Hashable {
    public let namespace: String
    public let name: String
    public let member: String?

    public init(_ id: String) throws {
        let splitOnPound = id.split(separator: "#")
        guard splitOnPound.count == 2 else {
            throw ModelError("id \"\(id)\" does not have a #")
        }
        guard let namespace = splitOnPound.first, !namespace.isEmpty else {
            throw ModelError("id \"\(id)\" does not have a nonempty namespace")
        }
        self.namespace = String(namespace)
        guard let name = splitOnPound.last, !name.isEmpty else {
            throw ModelError("id \"\(id)\" does not have a nonempty name")
        }
        self.name = String(name)
        self.member = nil
    }

    public init(id: ShapeID, member: String) {
        self.namespace = id.namespace
        self.name = id.name
        self.member = member
    }

    public var id: String {
        if let member {
            return "\(namespace)#\(name)$\(member)"
        } else {
            return "\(namespace)#\(name)"
        }
    }
}

extension ShapeID: Comparable {

    public static func < (lhs: ShapeID, rhs: ShapeID) -> Bool {
        return lhs.id.lowercased() < rhs.id.lowercased()
    }
}

extension ShapeID: CustomStringConvertible {

    /// Returns the absolute Shape ID in a single, printable string.
    public var description: String { id }
}
