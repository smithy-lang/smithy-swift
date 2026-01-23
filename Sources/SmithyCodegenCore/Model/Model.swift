//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID

/// An in-memory representation of a Smithy model, suitable for use in code generation.
public class Model {

    /// The Smithy version that this model conforms to.  This type supports `1.0` and `2.0`.
    public let version: String
    
    /// The model metadata.
    public let metadata: Node?
    
    /// All shapes in the model, keyed by their absolute ShapeID.
    public let shapes: [ShapeID: Shape]

    /// An array of all shapes in the model, in Smithy-sorted order.
    public let allShapesSorted: [Shape]
    
    /// Creates a new model.
    ///
    /// When a ``Model`` is created from another model, the shapes are updated to point to the new model
    /// for reference resolution.  The old model should no longer be used once a new model is created from it.
    /// - Parameters:
    ///   - version: The Smithy version that the model conforms to.
    ///   - metadata: The model metadata.
    ///   - shapes: A dictionary of all shapes in the model, keyed by their absolute Shape IDs.
    init(version: String, metadata: Node?, shapes: [ShapeID: Shape]) {
        self.version = version
        self.metadata = metadata
        self.shapes = shapes

        // Sort the shapes in the dictionary & store them in an array.
        self.allShapesSorted = Array(shapes.values).smithySorted()

        // self is now fully initialized.
        // Set the model on each shape to self.
        shapes.values.forEach { $0.model = self }
    }
    
    /// Returns the shape for the passed ID.  Throws if the shape is not present.
    /// - Parameter id: The ShapeID for the shape to be retrieved.
    /// - Returns: The retrieved shape.  Throws if the shape is not found.
    func expectShape(id: ShapeID) throws -> Shape {
        guard let shape = shapes[id] else {
            throw ModelError("ShapeID \(id) was expected in model but not found")
        }
        return shape
    }

    /// Returns the service for the passed ID.  Throws if the shape is not present or not a ``ServiceShape``.
    /// - Parameter id: The ShapeID for the service to be retrieved.
    /// - Returns: The retrieved shape.  Throws if the shape is not found or not a ``ServiceShape``.
    func expectServiceShape(id: ShapeID) throws -> ServiceShape {
        guard let shape = try expectShape(id: id) as? ServiceShape else {
            throw ModelError("ShapeID \(id) is not a ServiceShape")
        }
        return shape
    }

    /// Returns the resource for the passed ID.  Throws if the shape is not present or not a ``ResourceShape``.
    /// - Parameter id: The ShapeID for the resource to be retrieved.
    /// - Returns: The retrieved resource.  Throws if the shape is not found or not a ``ResourceShape``.
    func expectResourceShape(id: ShapeID) throws -> ResourceShape {
        guard let shape = try expectShape(id: id) as? ResourceShape else {
            throw ModelError("ShapeID \(id) is not a ResourceShape")
        }
        return shape
    }

    /// Returns the operation for the passed ID.  Throws if the shape is not present or not a ``OperationShape``.
    /// - Parameter id: The ShapeID for the operation to be retrieved.
    /// - Returns: The retrieved operation.  Throws if the shape is not found or not a ``OperationShape``.
    func expectOperationShape(id: ShapeID) throws -> OperationShape {
        guard let shape = try expectShape(id: id) as? OperationShape else {
            throw ModelError("ShapeID \(id) is not a OperationShape")
        }
        return shape
    }

    /// Returns the structure for the passed ID.  Throws if the shape is not present or not a ``StructureShape``.
    /// - Parameter id: The ShapeID for the structure to be retrieved.
    /// - Returns: The retrieved structure.  Throws if the shape is not found or not a ``StructureShape``.
    func expectStructureShape(id: ShapeID) throws -> StructureShape {
        guard let shape = try expectShape(id: id) as? StructureShape else {
            throw ModelError("ShapeID \(id) is not a StructureShape")
        }
        return shape
    }

    /// Returns the list for the passed ID.  Throws if the shape is not present or not a ``ListShape``.
    /// - Parameter id: The ShapeID for the list to be retrieved.
    /// - Returns: The retrieved list.  Throws if the shape is not found or not a ``ListShape``.
    func expectListShape(id: ShapeID) throws -> ListShape {
        guard let shape = try expectShape(id: id) as? ListShape else {
            throw ModelError("ShapeID \(id) is not a ListShape")
        }
        return shape
    }

    /// Returns the map for the passed ID.  Throws if the shape is not present or not a ``MapShape``.
    /// - Parameter id: The ShapeID for the map to be retrieved.
    /// - Returns: The retrieved map.  Throws if the shape is not found or not a ``MapShape``.
    func expectMapShape(id: ShapeID) throws -> MapShape {
        guard let shape = try expectShape(id: id) as? MapShape else {
            throw ModelError("ShapeID \(id) is not a MapShape")
        }
        return shape
    }

    /// Returns the member for the passed ID.  Throws if the shape is not present or not a ``MemberShape``.
    /// - Parameter id: The ShapeID for the member to be retrieved.
    /// - Returns: The retrieved member.  Throws if the shape is not found or not a ``MemberShape``.
    func expectMemberShape(id: ShapeID) throws -> MemberShape {
        guard let shape = try expectShape(id: id) as? MemberShape else {
            throw ModelError("ShapeID \(id) is not a MemberShape")
        }
        return shape
    }
}
