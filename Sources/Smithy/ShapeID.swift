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
public struct ShapeID: Hashable, Sendable {
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

    public init(_ id: String) throws {
        let splitOnPound = id.split(separator: "#")
        guard splitOnPound.count == 2 else {
            throw ShapeIDError("id \"\(id)\" does not have a #")
        }
        guard let namespace = splitOnPound.first, !namespace.isEmpty else {
            throw ShapeIDError("id \"\(id)\" does not have a nonempty namespace")
        }
        self.namespace = String(namespace)
        let splitOnDollar = splitOnPound.last!.split(separator: "$")
        switch splitOnDollar.count {
        case 2:
            self.name = String(splitOnDollar.first!)
            self.member = String(splitOnDollar.last!)
        case 1:
            self.name = String(splitOnDollar.first!)
            self.member = nil
        default:
            throw ShapeIDError("id \"\(id)\" has more than one $")
        }
    }

    public init(id: ShapeID, member: String?) {
        self.namespace = id.namespace
        self.name = id.name
        self.member = member
    }

    public var absoluteID: String {
        return "\(namespace)#\(relativeID)"
    }

    public var relativeID: String {
        if let member {
            return "\(name)$\(member)"
        } else {
            return "\(name)"
        }
    }
}

extension ShapeID: Comparable {

    // This logic matches the sorting logic used by the Java-based codegen
    public static func < (lhs: ShapeID, rhs: ShapeID) -> Bool {
        lhs.absoluteID.lowercased() < rhs.absoluteID.lowercased()
    }
}

extension ShapeID: CustomStringConvertible {

    /// Returns the absolute Shape ID in a single, printable string.
    public var description: String { absoluteID }
}

public struct ShapeIDError: Error {
    public let localizedDescription: String

    init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}
