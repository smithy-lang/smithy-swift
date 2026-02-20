//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.EnumValueTrait
import enum Smithy.Node
import enum Smithy.Prelude
import struct Smithy.ShapeID
import struct Smithy.TraitCollection

extension Model {

    /// Creates a Smithy model from a JSON AST model.
    ///
    /// Compared to the AST model, this model has custom shape types, members are included in the main body of shapes
    /// along with other shape types, and all Shape IDs are fully-qualified
    /// (i.e. members have the enclosing shape's namespace & name, along with their own member name.)
    /// - Parameter astModel: The JSON AST model to create a `Model` from.
    convenience init(astModel: ASTModel) throws {
        // Get all of the members from the AST model, create pairs of ShapeID & MemberShape
        let idToMemberShapePairs = try astModel.shapes
            .flatMap { try Self.memberShapePairs(id: $0.key, astShape: $0.value) }
        let memberShapes = Dictionary(uniqueKeysWithValues: idToMemberShapePairs)

        // Get all of the non-members from the AST model, create pairs of ShapeID & various shape subclasses
        let idToShapePairs = try astModel.shapes
            .map { try Self.shapePair(id: $0.key, astShape: $0.value, memberShapes: memberShapes) }

        // Combine all shapes (member & nonmember) into one large Dict for inclusion in the model
        let shapes = Dictionary(uniqueKeysWithValues: idToShapePairs + idToMemberShapePairs)

        // Initialize with the shape dictionary
        self.init(version: astModel.smithy, metadata: astModel.metadata, shapes: shapes)
    }

    private static func memberShapePairs(id: String, astShape: ASTShape) throws -> [(ShapeID, MemberShape)] {
        var baseMembers = astShape.members ?? [:]

        // If this AST shape is an array, add a member for its element
        if let member = astShape.member {
            baseMembers["member"] = member
        }

        // If this AST shape is a map, add members for its key & value
        if let key = astShape.key {
            baseMembers["key"] = key
        }
        if let value = astShape.value {
            baseMembers["value"] = value
        }

        // If this shape is a string with the enum trait, add members for its trait members
        if astShape.type == .string, let enumTraitNode = astShape.traits?[EnumTrait.id.absolute] {
            let enumTrait = try EnumTrait(node: enumTraitNode)
            let unitID = Smithy.Prelude.unitSchema.id.absolute
            enumTrait.members.forEach { enumMember in
                let name = enumMember.name ?? enumMember.value
                let traits: [String: Node] = if enumMember.name != nil {
                    [EnumValueTrait.id.absolute: .string(enumMember.value)]
                } else {
                    [:]
                }
                baseMembers[name] = ASTMember(target: unitID, traits: traits)
            }
        }

        // Map the AST members to ShapeID-to-MemberShape pairs & return the list of pairs
        return try baseMembers.map { astMember in
            // Create a ShapeID for this member
            let memberID = ShapeID(id: try ShapeID(id), member: astMember.key)

            // Create traits for this member
            let traitPairs = try astMember.value.traits?.map { (try ShapeID($0.key), $0.value) }
            let traitDict = Dictionary(uniqueKeysWithValues: traitPairs ?? [])
            let traits = TraitCollection(traits: traitDict)

            // Create a Shape ID for this member's target
            let targetID = try ShapeID(astMember.value.target)

            // Create the ShapeID-to-MemberShape pair
            return (memberID, MemberShape(id: memberID, traits: traits, targetID: targetID))
        }
    }

    // swiftlint:disable:next function_body_length
    private static func shapePair(
        id: String, astShape: ASTShape, memberShapes: [ShapeID: MemberShape]
    ) throws -> (ShapeID, Shape) {
        // Create the ShapeID for this shape from the AST shape's string ID.
        let shapeID = try ShapeID(id)

        // Create model traits from the AST traits.
        let idToTraitPairs = try astShape.traits?.map { (try ShapeID($0.key), $0.value) } ?? []
        let traitDict = Dictionary(uniqueKeysWithValues: idToTraitPairs)
        let traits = TraitCollection(traits: traitDict)

        // Based on the AST shape type, create the appropriate Shape type.
        switch astShape.type {
        case .service:
            let shape = ServiceShape(
                id: shapeID,
                traits: traits,
                operationIDs: try astShape.operations?.map { try $0.id } ?? [],
                resourceIDs: try astShape.resources?.map { try $0.id } ?? [],
                errorIDs: try astShape.errors?.map { try $0.id } ?? []
            )
            return (shapeID, shape)
        case .resource:
            let shape = ResourceShape(
                id: shapeID,
                traits: traits,
                operationIDs: try astShape.operations?.map { try $0.id } ?? [],
                createID: try astShape.create?.id,
                putID: try astShape.put?.id,
                readID: try astShape.read?.id,
                updateID: try astShape.update?.id,
                deleteID: try astShape.delete?.id,
                listID: try astShape.list?.id
            )
            return (shapeID, shape)
        case .operation:
            let shape = OperationShape(
                id: shapeID,
                traits: traits,
                inputID: try astShape.input?.id,
                outputID: try astShape.output?.id,
                errorIDs: try astShape.errors?.map { try $0.id } ?? []
            )
            return (shapeID, shape)
        case .structure:
            let shape = StructureShape(
                id: shapeID,
                traits: traits,
                memberIDs: memberIDs(for: shapeID, memberShapes: memberShapes)
            )
            return (shapeID, shape)
        case .union:
            let shape = UnionShape(
                id: shapeID,
                traits: traits,
                memberIDs: memberIDs(for: shapeID, memberShapes: memberShapes)
            )
            return (shapeID, shape)
        case .enum:
            let shape = EnumShape(
                id: shapeID,
                traits: traits,
                memberIDs: memberIDs(for: shapeID, memberShapes: memberShapes)
            )
            return (shapeID, shape)
        case .intEnum:
            let shape = IntEnumShape(
                id: shapeID,
                traits: traits,
                memberIDs: memberIDs(for: shapeID, memberShapes: memberShapes)
            )
            return (shapeID, shape)
        case .list, .set:
            let shape = ListShape(
                id: shapeID,
                traits: traits,
                memberIDs: memberIDs(for: shapeID, memberShapes: memberShapes)
            )
            return (shapeID, shape)
        case .map:
            let shape = MapShape(
                id: shapeID,
                traits: traits,
                memberIDs: memberIDs(for: shapeID, memberShapes: memberShapes)
            )
            return (shapeID, shape)
        case .string:
            if traits.hasTrait(EnumTrait.self) {
                // The enum trait is a holdover from Smithy 1.0 and is deprecated in favor of
                // the enum shape.
                // If this is a String with enum trait, convert it to a EnumShape.
                let shape = EnumShape(
                    id: shapeID,
                    traits: traits,
                    memberIDs: memberIDs(for: shapeID, memberShapes: memberShapes)
                )
                return (shapeID, shape)
            } else {
                let shape = StringShape(id: shapeID, traits: traits)
                return (shapeID, shape)
            }
        case .integer:
            let shape = IntegerShape(id: shapeID, traits: traits)
            return (shapeID, shape)
        default:
            let shape = Shape(
                id: shapeID,
                type: try astShape.type.modelType,
                traits: traits
            )

            // Return the ShapeID-to-Shape pair.
            return (shapeID, shape)
        }
    }

    private static func memberIDs(for shapeID: ShapeID, memberShapes: [ShapeID: MemberShape]) -> [ShapeID] {
        // Given all the member shapes in this model, select the ones for the passed shape ID
        // and return their IDs in sorted order.
        memberShapes.keys.filter {
            $0.namespace == shapeID.namespace && $0.name == shapeID.name && $0.member != nil
        }.sorted()
    }
}
