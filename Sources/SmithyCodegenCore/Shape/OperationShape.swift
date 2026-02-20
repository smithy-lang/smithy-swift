//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import enum Smithy.Prelude
import struct Smithy.ShapeID
import enum Smithy.ShapeType
import struct Smithy.TraitCollection

/// A ``Shape`` subclass specialized for Smithy operations.
public class OperationShape: Shape {
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
