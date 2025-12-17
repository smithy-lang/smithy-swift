//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID

public class Model {
    public let version: String
    public let metadata: Node?
    public let shapes: [ShapeID: Shape]

    init(version: String, metadata: Node?, shapes: [ShapeID: Shape]) {
        self.version = version
        self.metadata = metadata
        self.shapes = shapes
    }

    func expectShape(id: ShapeID) throws -> Shape {
        guard let shape = shapes[id] else {
            throw ModelError("ShapeID \(id) was expected in model but not found")
        }
        return shape
    }
}
