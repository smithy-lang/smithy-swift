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
class OperationShape: Shape {
    let inputShapeID: ShapeID?
    let outputShapeID: ShapeID?

    public init(id: ShapeID, traits: [ShapeID: Node], input: ShapeID?, output: ShapeID?) {
        self.inputShapeID = input
        self.outputShapeID = output
        super.init(id: id, type: .operation, traits: traits)
    }

    public var input: Shape {
        if let inputShapeID {
            return model.shapes[inputShapeID]!.adding(traits: [.init("smithy.api", "input"): [:]])
        } else {
            let traits: [ShapeID: Node] = [
                .init("smithy.api", "input"): [:],
                .init("swift.synthetic", "operationName"): .string(id.id),
            ]
            return Shape.unit.adding(traits: traits)
        }
    }

    public var output: Shape {
        if let outputShapeID {
            return model.shapes[outputShapeID]!.adding(traits: [.init("smithy.api", "output"): [:]])
        } else {
            let traits: [ShapeID: Node] = [
                .init("smithy.api", "input"): [:],
                .init("swift.synthetic", "operationName"): .string(id.id),
            ]
            return Shape.unit.adding(traits: traits)
        }
    }
}
