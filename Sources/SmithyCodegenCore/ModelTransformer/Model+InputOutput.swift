//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import enum Smithy.Prelude
import struct Smithy.ShapeID
import struct Smithy.TargetsUnitTrait
import struct Smithy.TraitCollection

extension Model {

    /// Creates an empty structure in place of operation inputs & outputs that target `smithy.api#Unit`
    /// or that have no target.  Applies the `TargetsUnitTrait` to these synthesized structures as well.
    /// - Returns: The transformed model.
    func withSynthesizedInputsOutputs() throws -> Model {

        // Get the operations in the model
        let operations = shapes.values
            .filter { $0.type == .operation }
            .compactMap { $0 as? OperationShape }

        // Make a copy of this model's shapes to modify
        var newShapes = shapes

        for operation in operations {
            // Make new "synthetic" ShapeIDs for this operation's input & output
            let newInputShapeID = ShapeID("swift.synthetic", "\(operation.id.name)Input")
            let newOutputShapeID = ShapeID("swift.synthetic", "\(operation.id.name)Output")

            // Get the input & output structures for this operation.  Substitute an empty
            // structure if ID is omitted or targets Unit
            let inputShape = if operation.inputID == Prelude.unitSchema.id {
                StructureShape(id: Prelude.unitSchema.id, traits: [TargetsUnitTrait()], memberIDs: [])
            } else {
                try expectStructureShape(id: operation.inputID)
            }
            let outputShape = if operation.outputID == Prelude.unitSchema.id {
                StructureShape(id: Prelude.unitSchema.id, traits: [TargetsUnitTrait()], memberIDs: [])
            } else {
                try expectStructureShape(id: operation.outputID)
            }

            // Make new input and output shapes, plus their members, with the new ID
            let newInput = newStruct(newID: newInputShapeID, original: inputShape)
            let newInputShapeMembers = try renamedMembers(newID: newInputShapeID, original: inputShape)
            let newOutput = newStruct(newID: newOutputShapeID, original: outputShape)
            let newOutputShapeMembers = try renamedMembers(newID: newOutputShapeID, original: outputShape)

            // Add the new input & output and their members to the new shape dictionary.
            // The originals will remain and will be pruned later if they are left unreferenced.
            newShapes[newInput.id] = newInput
            newInputShapeMembers.forEach { newShapes[$0.id] = $0 }
            newShapes[newOutput.id] = newOutput
            newOutputShapeMembers.forEach { newShapes[$0.id] = $0 }

            // Make a new operation with the new input & output IDs
            let newOperation = OperationShape(
                id: operation.id,
                traits: operation.traits,
                inputID: newInputShapeID,
                outputID: newOutputShapeID,
                errorIDs: operation.errorIDs
            )

            // Add the new operation to the new shapes.  It will replace the original
            // since the new operation has the same ID.
            newShapes[newOperation.id] = newOperation
        }
        // Return the new model with the updated shapes.
        return Model(version: version, metadata: metadata, shapes: newShapes)
    }

    private func newStruct(newID: ShapeID, original: StructureShape) -> StructureShape {
        StructureShape(
            id: newID,
            traits: original.traits,
            memberIDs: original.memberIDs.map { .init(id: newID, member: $0.member) }
        )
    }

    private func renamedMembers(newID: ShapeID, original: StructureShape) throws -> [MemberShape] {
        let originalMembers = try original.memberIDs.map { try expectMemberShape(id: $0) }
        return originalMembers.map { member in
            MemberShape(
                id: .init(id: newID, member: member.id.member),
                traits: member.traits,
                targetID: member.targetID
            )
        }
    }
}
