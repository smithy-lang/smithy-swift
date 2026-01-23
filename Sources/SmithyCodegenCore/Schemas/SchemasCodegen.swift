//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import let Smithy.allSupportedTraits
import struct Smithy.ShapeID
import enum Smithy.ShapeType

/// A generator for the `Schemas.swift`
package struct SchemasCodegen {

    package init() {}
    
    /// Generates the `Schemas.swift` file for a modeled service.
    /// - Parameter ctx: The generation context to be used for codegen.
    /// - Returns: The contents of the `Schemas.swift` source file.
    package func generate(ctx: GenerationContext) throws -> String {
        let writer = SwiftWriter()
        writer.write("import struct Smithy.Schema")
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

        for shape in allShapes {

            // Render an internal-scoped, computed var in the global namespace for this schema.
            try writer.openBlock("var \(shape.schemaVarName): Smithy.Schema {", "}") { writer in
                try writeSchema(writer: writer, shape: shape)
                writer.unwrite(",")
            }
            writer.write("")

            // If a schema has a member that targets the schema itself, we avoid a compile warning for
            // self-reference by generating a duplicate schema var that references this schema, and we
            // will target the duplicate instead.
            //
            // This happens ~20 times in AWS models so it is not so frequent that the extra var will bloat
            // service clients.
            if let hm = shape as? HasMembers, try hm.members.contains(where: { $0.targetID == shape.id }) {
                try writer.openBlock("var dup_of_\(shape.schemaVarName): Smithy.Schema {", "}") { writer in
                    try writer.write(shape.schemaVarName)
                }
                writer.write("")
            }
        }
        writer.unwrite("\n")
        return writer.contents
    }

    private func writeSchema(writer: SwiftWriter, shape: Shape, index: Int? = nil) throws {

        // Open the initializer
        try writer.openBlock(".init(", "),") { writer in

            // Write the id: and type: params.  All schemas will have this
            writer.write("id: \(shape.id.rendered),")
            writer.write("type: .\(shape.type),")

            // Get the trait IDs for traits that are allow-listed for the schema & sort
            let traitIDs = Array(shape.traits.schemaTraits.traitDict.keys).smithySorted()

            // If there are any traits, write the traits: param
            if !traitIDs.isEmpty {
                writer.openBlock("traits: [", "],") { writer in
                    for traitID in traitIDs {
                        let trait = shape.traits.traitDict[traitID]!
                        writer.write("\(traitID.rendered): \(trait.rendered),")
                    }
                }
            }

            // Get the members for this shape
            let members = try (shape as? HasMembers)?.members ?? []

            // If there are any members, write the members param
            if !members.isEmpty {
                try writer.openBlock("members: [", "],") { writer in
                    for (index, member) in members.enumerated() {
                        // Make a recursive call to this method to render the member
                        try writeSchema(writer: writer, shape: member, index: index)
                    }
                }
            }

            // If this shape is a member, write the target: param
            if let member = shape as? MemberShape {
                let target = try member.target

                // If this schema's target is the same as itself, target the duplicate
                // (see above) to avoid a self-reference compile warning.
                let prefix = target.id == member.containerID ? "dup_of_" : ""
                writer.write(try "target: \(prefix)\(target.schemaVarName),")
            }

            // Write the index: param if one was passed.  Only members will have an index.
            if let index {
                writer.write("index: \(index),")
            }

            // Get rid of the trailing comma since Swift 5.x will fail to compile on a
            // method param trailing comma.
            writer.unwrite(",")
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
            return ".init(\(namespaceLiteral), \(nameLiteral), \(memberLiteral))"
        } else {
            return ".init(\(namespaceLiteral), \(nameLiteral))"
        }
    }
}
