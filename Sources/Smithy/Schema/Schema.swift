//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A class which describes selected, modeled information for a Smithy shape.
///
/// Typically, the Schema contains only modeled info & properties that are relevant to
/// serialization, transport bindings, and other functions performed by the SDK.
public struct Schema: Sendable {

    /// The Smithy shape ID for the shape described by this schema.
    public let id: ShapeID

    /// The type of the shape being described.
    public let type: ShapeType

    /// A dictionary of the described shape's trait shape IDs to Nodes with trait data.
    ///
    /// Not all traits for a shape will be represented in the schema;
    /// typically the Schema contains only the traits relevant to the client-side SDK.
    public let traits: TraitCollection

    /// The member schemas for this schema, if any.
    ///
    /// Typically only a schema of type Structure, Union, Enum, IntEnum, List or Map will have members.
    public let members: [Schema]

    /// The target schema for this schema.  Will only be used when this is a member schema.
    public var target: Schema? {
        _target()
    }

    /// Target schema is passed as an autoclosure so that schemas with self-referencing targets will not cause
    /// an infinite loop when accessed.
    private let _target: @Sendable () -> Schema?

    /// The index of this schema, if it represents a Smithy member.
    ///
    /// For a member schema, index will be set to its index in the members array.
    /// For other types of schema, index will be `-1`.
    ///
    /// This index is intended for use as a performance enhancement when looking up member schemas
    /// during deserialization.
    public let index: Int

    /// Creates a new Schema using the passed parameters.
    ///
    /// No validation is performed on the parameters since calls to this initializer
    /// are almost always code-generated from a previously validated Smithy model.
    public init(
        id: ShapeID,
        type: ShapeType,
        traits: TraitCollection = TraitCollection(),
        members: [Schema] = [],
        target: @Sendable @escaping @autoclosure () -> Schema? = nil,
        index: Int = -1
    ) {
        self.id = id
        self.type = type
        self.traits = traits
        self.members = members
        self._target = target
        self.index = index
    }

    /// Checks if a schema has a trait, by trait type.
    /// - Parameter type: The trait type to be checked.
    /// - Returns: `true` if the schema has a trait for the passed trait, `false` otherwise.
    public func hasTrait<T: Trait>(_ type: T.Type) -> Bool {
        return traits.hasTrait(T.self)
    }

    /// Gets a trait from the schema.
    /// - Parameter type: The trait to be retrieved.
    /// - Returns: The requested trait, or `nil` if the schema doesn't have that trait.
    public func getTrait<T: Trait>(_ type: T.Type) throws -> T? {
        try traits.getTrait(type)
    }

    /// Returns the member for a List's element.
    ///
    /// Only access this property on a schema of type `.list`.
    public var member: Schema {
        members[0] // `member` will be the only member in a list schema
    }

    /// Returns the key member for a Map's key.
    ///
    /// Only access this property on a schema of type `.map`.
    public var key: Schema {
        members[0] // `key` will be the first member in a map schema, before `value`
    }

    /// Returns the value member for a Map's value.
    ///
    /// Only access this property on a schema of type `.map`.
    public var value: Schema {
        members[1] // `value` will be the second / last member in a map schema, after `key`
    }
}
