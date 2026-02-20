//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Prelude
import struct Smithy.ShapeID

extension Model {

    /// smithy-swift mistakenly creates a structure for an enum case with an associated value for a union
    /// member that targets `smithy.api#Unit`.  To ensure that these structures get SerializableStruct /
    /// DeserializableStruct conformance, we replace `smithy.api#Unit` with a structure named `Unit` in the
    /// union's namespace.
    /// - Returns: The transformed model.
    func withUnionsTargetingUnitAdded() throws -> Model {
        var unitSubstitute: Shape?

        var newShapes = try shapes.mapValues { shape in
            guard let member = shape as? MemberShape else { return shape }
            guard try member.container.type == .union else { return member }
            guard member.targetID == Smithy.Prelude.unitSchema.id else { return member }
            let unitSubstituteID = ShapeID(member.id.namespace, "Unit")
            unitSubstitute = unitSubstitute ?? StructureShape(
                id: unitSubstituteID,
                traits: [:],
                memberIDs: []
            )
            let newMember = MemberShape(
                id: member.id,
                traits: member.traits,
                targetID: unitSubstituteID
            )
            return newMember
        }

        if let unitSubstitute, newShapes[unitSubstitute.id] == nil {
            newShapes[unitSubstitute.id] = unitSubstitute
        }

        return Model(version: self.version, metadata: self.metadata, shapes: newShapes)
    }
}
