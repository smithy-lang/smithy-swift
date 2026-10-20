//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import enum Smithy.Prelude
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID

extension Model {

    /// smithy-swift mistakenly creates a structure for an enum case with an associated value for a union
    /// member that targets `smithy.api#Unit`.  To ensure that these structures get SerializableStruct /
    /// DeserializableStruct conformance, we replace `smithy.api#Unit` with a synthesized structure
    /// named `Unit` in the model.
    /// - Returns: The transformed model.
    func withUnionsTargetingUnitAdded() throws -> Model {
        var unitSubstitutes = [ShapeID: Shape]()

        var newShapes = try shapes.mapValues { shape in

            // If a shape is not a member that is part of a union and targets smithy.api#Unit,
            // leave it unchanged
            guard let member = shape as? MemberShape else { return shape }
            guard try member.container.type == .union else { return member }
            guard member.targetID == Smithy.Prelude.unitSchema.id else { return member }

            // Create a new ID for the synthesized structure
            let unitSubstituteNamespace = "swift.synthetic.\(member.id.namespace)"
            let unitSubstituteID = ShapeID(unitSubstituteNamespace, "Unit")

            // Next, create a member that targets the new structure
            let newMember = MemberShape(
                id: member.id,
                traits: member.traits,
                targetID: unitSubstituteID
            )

            // Finally, create the target shape itself & save it for later insertion into the model
            // It's basically the unit shape, but with a different ID namespace and no UnitTypeTrait
            let unitSubstitute = StructureShape(
                id: unitSubstituteID,
                traits: [],
                memberIDs: []
            )
            unitSubstitutes[unitSubstitute.id] = unitSubstitute

            return newMember
        }

        // Insert the union substitutes into the model, else the members will get pruned later
        for unitSubstitute in unitSubstitutes.values {
            newShapes[unitSubstitute.id] = unitSubstitute
        }

        // Return a new model with the modified / added shapes
        return Model(version: self.version, metadata: self.metadata, shapes: newShapes, traitTypes: self.traitTypes)
    }
}
