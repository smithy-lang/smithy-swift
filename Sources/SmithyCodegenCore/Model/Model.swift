//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import class Foundation.JSONDecoder
import struct Foundation.URL

public class Model {
    public let version: String
    public let metadata: Node?
    public let shapes: [ShapeID: Shape]

    public convenience init(modelFileURL: URL) throws {
        let modelData = try Data(contentsOf: modelFileURL)
        let astModel = try JSONDecoder().decode(ASTModel.self, from: modelData)
        try self.init(astModel: astModel)
    }

    init(astModel: ASTModel) throws {
        self.version = astModel.smithy
        self.metadata = astModel.metadata?.modelNode
        let idToShapePairs = try astModel.shapes.map { try Self.shapePair(id: $0.key, astShape: $0.value) }
        let idToMemberShapePairs = try astModel.shapes.flatMap { astShape in
            try Self.memberShapePairs(id: astShape.key, astShape: astShape.value)
        }
        self.shapes = Dictionary(uniqueKeysWithValues: idToShapePairs + idToMemberShapePairs)

        // self is now initialized, perform post-initialization wireup

        // set the Shapes with references back to this model
        self.shapes.values.forEach { $0.model = self }

        // set the memberIDs for each Shape
        self.shapes.values.filter { $0.type != .member }.forEach { shape in
            let namespace = shape.id.namespace
            let name = shape.id.name
            let memberIDs: [ShapeID] = Array(self.shapes.keys)
            let filteredMemberIDs = memberIDs.filter {
                $0.namespace == namespace && $0.name == name && $0.member != nil
            }
            shape.memberIDs = filteredMemberIDs.sorted()
        }
    }

    private static func shapePair(id: String, astShape: ASTShape) throws -> (ShapeID, Shape) {
        let shapeID = try ShapeID(id)
        let idToTraitPairs = try astShape.traits?.map { (try ShapeID($0.key), $0.value.modelNode) } ?? []
        let shape = Shape(
            id: shapeID,
            type: astShape.type.modelType,
            traits: Dictionary(uniqueKeysWithValues: idToTraitPairs),
            targetID: nil
        )
        return (shapeID, shape)
    }

    private static func memberShapePairs(id: String, astShape: ASTShape) throws -> [(ShapeID, Shape)] {
        var baseMembers = (astShape.members ?? [:])
        if let member = astShape.member {
            baseMembers["member"] = member
        }
        if let key = astShape.key {
            baseMembers["key"] = key
        }
        if let value = astShape.value {
            baseMembers["value"] = value
        }
        return try baseMembers.map { astMember in
            let memberID = ShapeID(id: try ShapeID(id), member: astMember.key)
            let traitPairs = try astMember.value.traits?.map { (try ShapeID($0.key), $0.value.modelNode) }
            let traits = Dictionary(uniqueKeysWithValues: traitPairs ?? [])
            let targetID = try ShapeID(astMember.value.target)
            return (memberID, Shape(id: memberID, type: .member, traits: traits, targetID: targetID))
        }
    }

    func expectShape(id: ShapeID) throws -> Shape {
        guard let shape = shapes[id] else {
            throw ModelError("ShapeID \(id) was expected in model but not found")
        }
        return shape
    }
}
