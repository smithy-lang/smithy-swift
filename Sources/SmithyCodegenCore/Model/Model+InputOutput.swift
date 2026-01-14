//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID

extension Model {

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
            let inputShape = if operation.inputID == unitShapeID {
                StructureShape(id: unitShapeID, traits: [unitSubstituteTraitID: [:]], memberIDs: [])
            } else {
                try expectStructureShape(id: operation.inputID)
            }
            let outputShape = if operation.outputID == unitShapeID {
                StructureShape(id: unitShapeID, traits: [unitSubstituteTraitID: [:]], memberIDs: [])
            } else {
                try expectStructureShape(id: operation.outputID)
            }

            // Make new input and output shapes, plus their members, with the new ID
            // Add input and output traits to the input/output structures if they don't
            // have them already
            let newInputShape = newStructure(newID: newInputShapeID, traits: inputTrait, original: inputShape)
            let newInputShapeMembers = try renamedMembers(newID: newInputShapeID, original: inputShape)
            let newOutputShape = newStructure(newID: newOutputShapeID, traits: outputTrait, original: outputShape)
            let newOutputShapeMembers = try renamedMembers(newID: newOutputShapeID, original: outputShape)

            // Add the new input & output and their members to the new shape dictionary.
            // The originals will remain and will be pruned later if they are unreferenced.
            newShapes[newInputShape.id] = newInputShape
            newInputShapeMembers.forEach { newShapes[$0.id] = $0 }
            newShapes[newOutputShape.id] = newOutputShape
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

    private func newStructure(newID: ShapeID, traits: [ShapeID: Node], original: StructureShape) -> StructureShape {
        StructureShape(
            id: newID,
            traits: original.traits.adding(traits),
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

private var inputTrait: [ShapeID: Node] {
    [inputTraitID: [:]]
}

private var outputTrait: [ShapeID: Node] {
    [outputTraitID: [:]]
}

private var inputTraitID: ShapeID { .init("smithy.api", "input") }

private var outputTraitID: ShapeID { .init("smithy.api", "output") }

private var unitShapeID: ShapeID { .init("smithy.api", "Unit") }

private var unitSubstituteTraitID: ShapeID { .init("swift.synthetic", "unitSubstitute") }

private extension [ShapeID: Node] {

    func adding(_ additions: [ShapeID: Node]) -> [ShapeID: Node] {
        self.merging(additions) { _, new in new }
    }
}
