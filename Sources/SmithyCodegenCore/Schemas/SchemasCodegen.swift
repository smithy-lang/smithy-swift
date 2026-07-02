//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
@_spi(SchemaBasedSerde)
import protocol Smithy.RuntimeTrait
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID
import enum Smithy.ShapeType
@_spi(SchemaBasedSerde)
import protocol Smithy.Trait

/// A generator for the `Schemas.swift`
package struct SchemasCodegen {

    package init() {}

    /// Generates the `Schemas.swift` file for a modeled service.
    /// - Parameter ctx: The generation context to be used for codegen.
    /// - Returns: The contents of the `Schemas.swift` source file.
    package func generate(ctx: GenerationContext) throws -> String {
        let writer = SwiftWriter()
        // Many runtime trait types will likely be instantiated in this file,
        // along with other fundamental types in Smithy.  So import entire module.
        writer.write("@_spi(SchemaBasedSerde)")
        writer.write("import Smithy")
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

            // Get the TraitType-to-Node pairs for this shape's traits
            let traitPairs = try traitPairs(for: shape)

            // If there are any traits, write the traits: param
            if !traitPairs.isEmpty {
                writer.openBlock("traits: [", "],") { writer in
                    for (TraitType, node) in traitPairs {
                        // Traits are initialized using try? to convert any thrown error to nil.
                        // In practice, a trait should never throw at runtime, because every
                        // trait was already successfully constructed by the code generator
                        // while processing the model.
                        // The TraitCollection initializes from this array of optional Traits;
                        // nil elements are simply compacted out.
                        writer.write("try? Smithy.\(TraitType)(node: \(node.rendered)),")
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

    private func traitPairs(for shape: Shape) throws -> [(any Trait.Type, Node)] {
        if let memberShape = shape as? MemberShape {
            // Get all the trait IDs that apply to this member & sort
            // Only take runtime traits, others aren't used at runtime
            let memberTraitIDs = memberShape.traits.traitDict.filter { $0.value is any RuntimeTrait }.keys
            let targetTraitIDs = try memberShape.target.traits.traitDict.filter { $0.value is any RuntimeTrait }.keys
            let allTraitIDs = Array(Set(Array(memberTraitIDs) + targetTraitIDs)).smithySorted()

            // Iterate over every trait ID appearing in either the member or target
            var pairs = [(any Trait.Type, Node)]()
            for traitID in allTraitIDs {
                // Force-unwrap used here since this trait must be present in 1 of the 2 (member or target)
                let trait = try memberShape.traits.traitDict[traitID] ?? memberShape.target.traits.traitDict[traitID]!

                // Call the resolvedMemberTrait method for the type of trait involved
                // If a node is resolved, add it into the pairs, along with this trait type
                let TraitType = type(of: trait)
                if let resolvedNode = try TraitType.resolvedMemberTrait(
                    member: memberShape.traits.traitDict[traitID]?.node,
                    target: memberShape.target.traits.traitDict[traitID]?.node
                ) {
                    pairs.append((TraitType, resolvedNode))
                }
            }
            return pairs
        } else {
            // Get the trait IDs for runtime traits & sort
            let traitIDs = Array(shape.traits.traitDict.filter { $0.value is any RuntimeTrait }.keys).smithySorted()
            // Map sorted IDs into tuples with their node value
            return traitIDs.map { traitID in
                let trait = shape.traits.traitDict[traitID]!
                let TraitType = type(of: trait)
                return (TraitType, shape.traits.traitDict[traitID]!.node)
            }
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
