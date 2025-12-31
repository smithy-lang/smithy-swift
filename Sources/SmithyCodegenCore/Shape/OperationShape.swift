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
    let inputShapeID: ShapeID?
    let outputShapeID: ShapeID?

    public init(id: ShapeID, traits: [ShapeID: Node], input: ShapeID?, output: ShapeID?) {
        self.inputShapeID = input
        self.outputShapeID = output
        super.init(id: id, type: .operation, traits: traits)
    }

    public var input: StructureShape {
        model.shapes[inputShapeID ?? _syntheticInputID] as! StructureShape
    }

    public var output: StructureShape {
        model.shapes[outputShapeID ?? _syntheticOutputID] as! StructureShape
    }

    override var candidates: [Shape] {
        [_input, _output]
    }

    private var _input: Shape {
        if let inputShapeID {
            return model.shapes[inputShapeID]!
        } else {
            let traits: [ShapeID: Node] = [
                .init("smithy.api", "input"): [:],
                .init("swift.synthetic", "operationName"): .string(id.id),
            ]
            return StructureShape(id: _syntheticInputID, traits: traits, memberIDs: [])
        }
    }

    private var _syntheticInputID: ShapeID {
        .init("smithy.synthetic", "\(id.name)Input")
    }

    private var _output: Shape {
        if let outputShapeID {
            return model.shapes[outputShapeID]!
        } else {
            let traits: [ShapeID: Node] = [
                .init("smithy.api", "input"): [:],
                .init("swift.synthetic", "operationName"): .string(id.id),
            ]
            return StructureShape(id: _syntheticOutputID, traits: traits, memberIDs: [])
        }
    }

    private var _syntheticOutputID: ShapeID {
        .init("smithy.synthetic", "\(id.name)Output")
    }
}
