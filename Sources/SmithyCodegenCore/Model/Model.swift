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
    public let allShapesSorted: [Shape]

    init(version: String, metadata: Node?, shapes: [ShapeID: Shape]) {
        self.version = version
        self.metadata = metadata
        self.shapes = shapes
        self.allShapesSorted = Array(shapes.values).smithySorted()
        // self is now fully initialized.
        // Set the model on each shape to self.
        shapes.values.forEach { $0.model = self }
    }

    func expectShape(id: ShapeID) throws -> Shape {
        guard let shape = shapes[id] else {
            throw ModelError("ShapeID \(id) was expected in model but not found")
        }
        return shape
    }

    func expectServiceShape(id: ShapeID) throws -> ServiceShape {
        guard let serviceShape = try expectShape(id: id) as? ServiceShape else {
            throw ModelError("ShapeID \(id) is not a ServiceShape")
        }
        return serviceShape
    }

    func expectStructureShape(id: ShapeID) throws -> StructureShape {
        guard let structureShape = try expectShape(id: id) as? StructureShape else {
            throw ModelError("ShapeID \(id) is not a StructureShape")
        }
        return structureShape
    }

    func expectMemberShape(id: ShapeID) throws -> MemberShape {
        guard let memberShape = try expectShape(id: id) as? MemberShape else {
            throw ModelError("ShapeID \(id) is not a MemberShape")
        }
        return memberShape
    }
}
