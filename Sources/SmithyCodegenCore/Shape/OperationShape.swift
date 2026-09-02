//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
@_spi(SchemaBasedSerde)
import enum Smithy.Prelude
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID
import enum Smithy.ShapeType
@_spi(SchemaBasedSerde)
import struct Smithy.TraitCollection

/// A ``Shape`` subclass specialized for Smithy operations.
@_spi(SchemaBasedSerde)
public class OperationShape: Shape, HasMembers {
    let inputID: ShapeID
    let outputID: ShapeID
    let errorIDs: [ShapeID]

    public init(id: ShapeID, traits: TraitCollection, inputID: ShapeID?, outputID: ShapeID?, errorIDs: [ShapeID]) {
        self.inputID = inputID ?? Prelude.unitSchema.id
        self.outputID = outputID ?? Prelude.unitSchema.id
        self.errorIDs = errorIDs
        super.init(id: id, type: .operation, traits: traits)
    }

    public var input: StructureShape {
        get throws {
            try model.expectStructureShape(id: inputID)
        }
    }

    public var output: StructureShape {
        get throws {
            try model.expectStructureShape(id: outputID)
        }
    }

    public var errors: [StructureShape] {
        get throws {
            try errorIDs.map { try model.expectStructureShape(id: $0) }
        }
    }

    override func immediateDescendants(includeInput: Bool, includeOutput: Bool) throws -> Set<Shape> {
        let inputOrNone = try includeInput ? [input] : []
        let outputOrNone = try includeOutput ? [output] : []
        let errorsOrNone = try includeOutput ? errorIDs.map { try model.expectShape(id: $0) } : []
        return Set(inputOrNone + outputOrNone + errorsOrNone)
    }
}

// Members are synthesized into the model for the input & output relations.
// These will be rendered into schemas when code is generated.
// Synthesized members are used instead of input/output properties on schema to prevent adding
// new schema stored properties just for operations.
public extension OperationShape {

    var members: [MemberShape] {
        let members = [
            MemberShape(id: ShapeID(id: self.id, member: "input"), traits: [], targetID: self.inputID),
            MemberShape(id: ShapeID(id: self.id, member: "output"), traits: [], targetID: self.outputID),
        ]
        members.forEach { $0.model = self.model }
        return members
    }
}
