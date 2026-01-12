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
        guard let shape = try expectShape(id: id) as? ServiceShape else {
            throw ModelError("ShapeID \(id) is not a ServiceShape")
        }
        return shape
    }

    func expectResourceShape(id: ShapeID) throws -> ResourceShape {
        guard let shape = try expectShape(id: id) as? ResourceShape else {
            throw ModelError("ShapeID \(id) is not a ResourceShape")
        }
        return shape
    }

    func expectOperationShape(id: ShapeID) throws -> OperationShape {
        guard let shape = try expectShape(id: id) as? OperationShape else {
            throw ModelError("ShapeID \(id) is not a OperationShape")
        }
        return shape
    }

    func expectStructureShape(id: ShapeID) throws -> StructureShape {
        guard let shape = try expectShape(id: id) as? StructureShape else {
            throw ModelError("ShapeID \(id) is not a StructureShape")
        }
        return shape
    }

    func expectListShape(id: ShapeID) throws -> ListShape {
        guard let shape = try expectShape(id: id) as? ListShape else {
            throw ModelError("ShapeID \(id) is not a ListShape")
        }
        return shape
    }

    func expectMapShape(id: ShapeID) throws -> MapShape {
        guard let shape = try expectShape(id: id) as? MapShape else {
            throw ModelError("ShapeID \(id) is not a MapShape")
        }
        return shape
    }

    func expectMemberShape(id: ShapeID) throws -> MemberShape {
        guard let shape = try expectShape(id: id) as? MemberShape else {
            throw ModelError("ShapeID \(id) is not a MemberShape")
        }
        return shape
    }
}
