//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// An interface for working with Smithy traits stored in a ``TraitCollection``.
///
/// All traits have a ``Node`` associated with them, but will typically provide their properties
/// with convenient, type-safe accessors.
public protocol Trait {
    static var id: ShapeID { get }

    var node: Node { get }

    init(node: Node) throws

    static func resolvedMemberTrait(member: Node?, target: Node?) throws -> Node?
}

public extension Trait {

    /// Returns the trait's ID as an instance property.
    var id: ShapeID { Self.id }

    /// Returns the trait value to be applied to a member schema.
    ///
    /// Member schemas have each trait's value pre-resolved, based on the trait on the member shape and its
    /// target, to simplify serializer/deserializer logic and enhance runtime performance.
    /// - Parameters:
    ///   - member: The trait value from the member shape, or `nil` if none
    ///   - target: The trait value from the target shape, or `nil` if none
    /// - Returns: The trait value that should be used in a member schema.
    static func resolvedMemberTrait(member: Node?, target: Node?) throws -> Node? {
        // The default resolution is to take the trait on the member if present,
        // else the trait on the target if present, else nil.
        member ?? target
    }
}
