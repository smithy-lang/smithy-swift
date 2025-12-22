//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID
import enum Smithy.ShapeType

public class Shape {
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
        var c = Set<Shape>()
        descendants(&c)
        return c
    }

    private func descendants(_ descendants: inout Set<Shape>) {
        let shapes = candidates(for: self)
        for shape in shapes {
            if descendants.contains(shape) { continue }
            descendants.insert(shape)
            shape.descendants(&descendants)
        }
    }

    func candidates(for shape: Shape) -> [Shape] {
        [] // default.  May be overridden by Shape subclasses.
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
