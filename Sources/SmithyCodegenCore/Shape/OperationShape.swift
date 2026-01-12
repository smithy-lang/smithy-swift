//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID
import enum Smithy.ShapeType

/// A ``Shape`` subclass specialized for Smithy operations.
public class OperationShape: Shape {
    let inputID: ShapeID
    let outputID: ShapeID
    let errorIDs: [ShapeID]

    public init(id: ShapeID, traits: [ShapeID: Node], inputID: ShapeID?, outputID: ShapeID?, errorIDs: [ShapeID]) {
        self.inputID = inputID ?? .init("smithy.api", "Unit")
        self.outputID = outputID ?? .init("smithy.api", "Unit")
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
