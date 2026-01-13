//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID
import enum Smithy.ShapeType

public class Shape: HasShapeID {
    public let id: ShapeID
    public let type: ShapeType
    public let traits: [ShapeID: Node]
    weak var model: Model!

    public init(id: ShapeID, type: ShapeType, traits: [ShapeID: Node]) {
        self.id = id
        self.type = type
        self.traits = traits
    }

    public func hasTrait(_ traitID: ShapeID) -> Bool {
        traits[traitID] != nil
    }

    public func getTrait(_ traitID: ShapeID) -> Node? {
        traits[traitID]
    }

    public func adding(traits newTraits: [ShapeID: Node]) -> Shape {
        let combinedTraits = traits.merging(newTraits) { _, new in new }
        let new = Shape(id: id, type: type, traits: combinedTraits)
        new.model = model
        return new
    }

    public var descendants: Set<Shape> {
        get throws {
            var c = Set<Shape>()
            try descendants(descendants: &c, includeInput: true, includeOutput: true)
            return c
        }
    }

    public var inputDescendants: Set<Shape> {
        get throws {
            var c = Set<Shape>()
            try descendants(descendants: &c, includeInput: true, includeOutput: false)
            return c
        }
    }

    public var outputDescendants: Set<Shape> {
        get throws {
            var c = Set<Shape>()
            try descendants(descendants: &c, includeInput: false, includeOutput: true)
            return c
        }
    }

    private func descendants(descendants: inout Set<Shape>, includeInput: Bool, includeOutput: Bool) throws {
        for shape in try immediateDescendants(includeInput: includeInput, includeOutput: includeOutput) {
            if descendants.contains(shape) { continue }
            descendants.insert(shape)
            try shape.descendants(
                descendants: &descendants,
                includeInput: includeInput,
                includeOutput: includeOutput
            )
        }
    }

    /// Returns shapes that this shape refers to.
    ///
    /// Used to build a set of shapes for code generation purposes.
    /// - Parameters:
    ///   - includeInput: Whether to include shapes that are associated with input
    ///   - includeOutput: Whether to include shapes that are associated with input
    /// - Returns: A set of shapes that this shape refers to.
    func immediateDescendants(includeInput: Bool, includeOutput: Bool) throws -> Set<Shape> {
        [] // none by default.  Must be overridden by Shape subclasses that refer to descendant shape types.
    }
}

extension Shape: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Shape: Equatable {

    public static func == (lhs: Shape, rhs: Shape) -> Bool {
        lhs.id == rhs.id
    }
}

extension Shape: Comparable {

    public static func < (lhs: Shape, rhs: Shape) -> Bool {
        lhs.id < rhs.id
    }
}
