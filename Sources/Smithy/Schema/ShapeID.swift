//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Represents a single Smithy shape ID.
///
/// Shape ID is described in the Smithy 2.0 spec [here](https://smithy.io/2.0/spec/model.html#shape-id).
public struct ShapeID: Hashable {
    public let namespace: String
    public let name: String
    public let member: String?
    
    /// Creates a Shape ID for a Smithy shape.
    ///
    /// This initializer does no validation of length or of allowed characters in the Shape ID;
    /// that is to be ensured by the caller (typically calls to this initializer will be code-generated
    /// from previously validated Smithy models.)
    /// - Parameters:
    ///   - namespace: The namespace for this shape, i.e. `smithy.api`.
    ///   - name: The name for this shape, i.e. `Integer`.
    ///   - member: The optional member name for this shape.
    public init(_ namespace: String, _ name: String, _ member: String? = nil) {
        self.namespace = namespace
        self.name = name
        self.member = member
    }
}

extension ShapeID: CustomStringConvertible {
    
    /// Returns the absolute Shape ID in a single, printable string.
    public var description: String {
        if let member = self.member {
            return "\(namespace)#\(name)$\(member)"
        } else {
            return "\(namespace)#\(name)"
        }
    }
}
