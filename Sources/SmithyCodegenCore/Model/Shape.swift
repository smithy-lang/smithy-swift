//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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

    public var members: [Shape] {
        get throws {
            guard let model else { throw ModelError("id \"\(id)\" model not set") }
            return memberIDs.map { model.shapes[$0]! }
        }
    }

    public var target: Shape? {
        get throws {
            guard let targetID else { return nil }
            guard let model else { throw ModelError("id \"\(id)\" model not set") }
            return model.shapes[targetID]
        }
    }

    public var children: Set<Shape> {
        get throws {
            var c = Set<Shape>()
            try children(children: &c)
            return c
        }
    }

    private func children(children: inout Set<Shape>) throws {
        let shapes = try candidates(for: self)
        for shape in shapes {
            if children.contains(shape) { continue }
            children.insert(shape)
            try shape.members.map { try $0.target }.compactMap { $0 }.forEach {
                children.insert($0)
                try $0.children(children: &children)
            }
        }
    }

    private func candidates(for shape: Shape) throws -> [Shape] {
        (try [try shape.target] + shape.members.map { try $0.target }).compactMap { $0 }
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
