//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import let Smithy.allSupportedTraitIDs
import enum Smithy.Node
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID
import enum Smithy.ShapeType
@_spi(SchemaBasedSerde)
import func Smithy.traitType

/// A generator for the `Schemas.swift`
package struct SchemasCodegen {

    package init() {}

    /// Generates the `Schemas.swift` file for a modeled service.
    /// - Parameter ctx: The generation context to be used for codegen.
    /// - Returns: The contents of the `Schemas.swift` source file.
    package func generate(ctx: GenerationContext) throws -> String {
        let writer = SwiftWriter()
        writer.write("@_spi(SchemaBasedSerde)")
        writer.write("import class Smithy.Schema")
        writer.write("@_spi(SchemaBasedSerde)")
        writer.write("import struct Smithy.ShapeID")
        writer.write("@_spi(SchemaBasedSerde)")
        writer.write("import enum Smithy.Prelude")
        writer.write("")

        // Get all operations, sorted
        let sortedOperationShapes = ctx.model.allShapesSorted
            .filter { $0.type == .operation }

        // Get the rest of the shapes, sorted
        let sortedModelShapes: [Shape] = ctx.model.allShapesSorted
            .filter { ![ShapeType.service, .resource, .operation, .member].contains($0.type) }
            .filter { $0.id.namespace != "smithy.api" }

        // Combine shapes in order: service, operations sorted, models sorted
        let allShapes = [ctx.service] + sortedOperationShapes + sortedModelShapes

        // Render each shape's schema, followed by a separate schema for each of its members, if any
        for shape in allShapes {
            // First, render a schema var for the shape itself
            try writeSchema(ctx: ctx, writer: writer, shape: shape, containerType: nil, index: nil)

            // Then render a schema var for each of the shape's members, if any
            guard let memberShapes = try (shape as? HasMembers)?.members else { continue }
            for (index, member) in memberShapes.enumerated() {
                try writeSchema(ctx: ctx, writer: writer, shape: member, containerType: shape.type, index: index)
            }
        }
        // Get rid of last trailing whitespace
        writer.unwrite("\n")
        return writer.contents
    }

    private func writeSchema(
        ctx: GenerationContext,
        writer: SwiftWriter,
        shape: Shape,
        containerType: ShapeType?,
        index: Int?
    ) throws {
        // Assign to a global var & open the initializer.
        // If the type is not made explicit, a schema can get a "circular reference" compile error
        // when schema target causes a reference cycle.
        // This must be a vagary of the Swift expression type checking system
        let varName = try shape.schemaVarName
        try writer.openBlock("let \(varName): Smithy.Schema = Smithy.Schema(", ")") { writer in

            // Write the id: and type: params.  All schemas will have this
            writer.write("id: \(shape.id.rendered),")
            writer.write("type: .\(try shapeType(for: shape)),")

            // Get the ShapeID-to-Node pairs for this shape's traits
            let traitPairs = try traitPairs(for: shape)

            // If there are any traits, write the traits: param
            if !traitPairs.isEmpty {
                writer.openBlock("traits: [", "],") { writer in
                    for (traitID, node) in traitPairs {
                        writer.write("\(traitID.rendered): \(node.rendered),")
                    }
                }
            }

            // Get the members for this shape
            let members = try (shape as? HasMembers)?.members ?? []

            // If there are any members, write the members param
            // Members are rendered to separate schema vars, and those vars are referenced here
            // Not in-lining the member schemas reduces the expression type-checking burden at compile time
            if !members.isEmpty {
                try writer.openBlock("members: [", "],") { writer in
                    for member in members {
                        try writer.write("\(member.schemaVarName),")
                    }
                }
            }

            // If this shape is a member, write the containerType: and target: param
            if let member = shape as? MemberShape {
                if let containerType {
                    writer.write("containerType: .\(containerType),")
                }
                try writer.write("target: \(member.target.schemaVarName),")
            }

            // Write the index: param if one was passed.  Only members will have an index.
            if let index {
                writer.write("index: \(index),")
            }

            // Get rid of the trailing comma since Swift 5.x will fail to compile on a
            // method param trailing comma.
            writer.unwrite(",")
        }
        // Add whitespace before the next schema
        writer.write("")
    }

    private func shapeType(for shape: Shape) throws -> ShapeType {
        if let memberShape = shape as? MemberShape {
            return try memberShape.target.type
        }
        return shape.type
    }

    private func traitPairs(for shape: Shape) throws -> [(ShapeID, Node)] {
        if let memberShape = shape as? MemberShape {
            // Get all the trait IDs that apply to this member & sort
            let memberTraitIDs = Set(memberShape.traits.traitDict.keys)
            let targetTraitIDs = Set(try memberShape.target.traits.traitDict.keys)
            let allTraitIDs = Array(memberTraitIDs.union(targetTraitIDs)).smithySorted()

            var pairs = [(ShapeID, Node)]()
            for traitID in allTraitIDs {
                let TraitType = traitType(for: traitID)
                if let resolvedNode = try TraitType?.resolvedMemberTrait(
                    member: memberShape.traits.traitDict[traitID],
                    target: memberShape.target.traits.traitDict[traitID]
                ) {
                    pairs.append((traitID, resolvedNode))
                }
            }
            return pairs
        } else {
            // Get the trait IDs for traits that are allow-listed for the schema & sort
            let traitIDs = Array(shape.traits.schemaTraits.traitDict.keys).smithySorted()
            // Map sorted IDs into tuples with their node value
            return traitIDs.map { ($0, shape.traits.traitDict[$0]!) }
        }
    }
}

extension ShapeID {

    /// Change the Shape ID into a rendered ShapeID initializer call.
    var rendered: String {
        let namespaceLiteral = namespace.literal
        let nameLiteral = name.literal
        if let member {
            let memberLiteral = member.literal
            return "Smithy.ShapeID(\(namespaceLiteral), \(nameLiteral), \(memberLiteral))"
        } else {
            return "Smithy.ShapeID(\(namespaceLiteral), \(nameLiteral))"
        }
    }
}
