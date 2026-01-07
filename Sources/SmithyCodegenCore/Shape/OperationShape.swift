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
        if let inputID {
            self.inputID = inputID == .init("smithy.api", "Unit") ? Self._syntheticInputID(operationID: id) : inputID
        } else {
            self.inputID = Self._syntheticInputID(operationID: id)
        }
        if let outputID {
            self.outputID = outputID == .init("smithy.api", "Unit") ? Self._syntheticOutputID(operationID: id) : outputID
        } else {
            self.outputID = Self._syntheticOutputID(operationID: id)
        }
        self.errorIDs = errorIDs
        super.init(id: id, type: .operation, traits: traits)
    }

    public var input: StructureShape {
        model.shapes[inputID] as! StructureShape
    }

    public var output: StructureShape {
        model.shapes[outputID] as! StructureShape
    }

    override func candidates(includeInput: Bool, includeOutput: Bool) throws -> [Shape] {
        let inputOrNone = try includeInput ? [_input] : []
        let outputOrNone = try includeOutput ? [_output] : []
        let errorsOrNone = try includeOutput ? errorIDs.map { try model.expectShape(id: $0) } : []
        return inputOrNone + outputOrNone + errorsOrNone
    }

    private var _input: StructureShape {
        get throws {
            if inputID != Self._syntheticInputID(operationID: id) {
                guard let input = model.shapes[inputID] as? StructureShape else {
                    throw ModelError("Operation \"\(id)\" does not have input shape \"\(inputID)\"")
                }
                let newInput = StructureShape(id: input.id, traits: input.traits.adding(inputTraits), memberIDs: input.memberIDs)
                newInput.model = self.model
                return newInput
            } else {
                let newInput = StructureShape(id: Self._syntheticInputID(operationID: id), traits: inputTraits, memberIDs: [])
                newInput.model = self.model
                return newInput
            }
        }
    }

    private var inputTraits: [ShapeID: Node] {
        [
            .init("smithy.api", "input"): [:],
            .init("swift.synthetic", "inputOperationName"): .string(id.name),
        ]
    }

    private static func _syntheticInputID(operationID: ShapeID) -> ShapeID {
        .init("swift.synthetic", "\(operationID.name)Input")
    }

    private var _output: StructureShape {
        get throws {
            if outputID != Self._syntheticOutputID(operationID: id) {
                guard let output = model.shapes[outputID] as? StructureShape else {
                    throw ModelError("Operation \"\(id)\" does not have output shape \"\(outputID)\"")
                }
                let newOutput = StructureShape(id: output.id, traits: output.traits.adding(outputTraits), memberIDs: output.memberIDs)
                newOutput.model = self.model
                return newOutput
            } else {
                let newOutput = StructureShape(id: Self._syntheticOutputID(operationID: id), traits: outputTraits, memberIDs: [])
                newOutput.model = self.model
                return newOutput
            }
        }
    }

    private var outputTraits: [ShapeID: Node] {
        [
            .init("smithy.api", "output"): [:],
            .init("swift.synthetic", "outputOperationName"): .string(id.name),
        ]
    }

    private static func _syntheticOutputID(operationID: ShapeID) -> ShapeID {
        .init("swift.synthetic", "\(operationID.name)Output")
    }
}

private extension [ShapeID: Node] {

    func adding(_ additions: [ShapeID: Node]) -> [ShapeID: Node] {
        self.merging(additions) { old, new in new }
    }
}
