//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A structure which describes selected Smithy model information for a Smithy model shape.
///
/// Typically, the Schema contains only modeled info & properties that are relevant to
/// serialization, transport bindings, and other functions performed by the SDK.
public class Schema {

    /// The Smithy shape ID for the shape described by this schema.
    public let id: ShapeID
    
    /// The type of the shape being described.
    public let type: ShapeType
    
    /// A dictionary of the described shape's trait shape IDs to Nodes with trait data.
    ///
    /// Not all traits for a shape will be represented in the schema;
    /// typically the Schema contains only the traits relevant to the client-side SDK.
    public let traits: [ShapeID: Node]
    
    /// The member schemas for this schema, if any.
    ///
    /// Typically only a schema of type Structure, Union, Enum, IntEnum, List or Map will have members.
    public let members: [Schema]

    /// The target schema for this schema.  Will only be used when this is a member schema.
    public let target: Schema?

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
        traits: [ShapeID: Node] = [:],
        members: [Schema] = [],
        target: Schema? = nil,
        index: Int = -1
    ) {
        self.id = id
        self.type = type
        self.traits = traits
        self.members = members
        self.target = target
        self.index = index
    }
}

public extension Schema {

    /// The member name for this schema, if any.
    ///
    /// Member name is computed from the schema's ID.
    var memberName: String? {
        id.member
    }
}
