//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID
import enum Smithy.ShapeType
import enum Smithy.Node

public class Shape {
    public let id: ShapeID
    public let type: ShapeType
    public internal(set) var traits: [ShapeID: Node]
    var targetID: ShapeID?
    var memberIDs: [ShapeID] = []
    weak var model: Model?

    public init(id: ShapeID, type: ShapeType, traits: [ShapeID: Node], targetID: ShapeID?) {
        self.id = id
        self.type = type
        self.traits = traits
        self.targetID = targetID
    }

    public func hasTrait(_ traitID: ShapeID) -> Bool {
        traits[traitID] != nil
    }

    public func getTrait(_ traitID: ShapeID) -> Node? {
        traits[traitID]
    }

    public var members: [Shape] {
        guard let model else { return [] }
        return memberIDs.map { model.shapes[$0]! }
    }

    public var target: Shape? {
        guard let targetID else { return nil }
        return model?.shapes[targetID] ?? Shape.prelude[targetID]
    }

    public func adding(traits newTraits: [ShapeID: Node]) -> Shape {
        let combinedTraits = traits.merging(newTraits) { _, new in new }
        let new = Shape(id: id, type: type, traits: combinedTraits, targetID: targetID)
        new.memberIDs = memberIDs
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
            shape.members.map { $0.target }.compactMap { $0 }.forEach {
                descendants.insert($0)
                $0.descendants(&descendants)
            }
        }
    }

    private func candidates(for shape: Shape) -> [Shape] {
        ([shape.target] + shape.members.map { $0.target }).compactMap { $0 }
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
