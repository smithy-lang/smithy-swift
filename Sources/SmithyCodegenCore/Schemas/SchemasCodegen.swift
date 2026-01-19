//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import let Smithy.allSupportedTraits
import struct Smithy.ShapeID
import enum Smithy.ShapeType

package struct SchemasCodegen {

    package init() {}

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
            try writer.openBlock("var \(shape.schemaVarName): Smithy.Schema {", "}") { writer in
                try writeSchema(writer: writer, shape: shape)
                writer.unwrite(",")
            }
            writer.write("")

            // If a schema has a member that targets the schema itself, we avoid a compile warning for
            // self-reference by generating a duplicate schema var that references this schema, and we
            // target the duplicate instead.
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
        try writer.openBlock(".init(", "),") { writer in
            writer.write("id: \(shape.id.rendered),")
            writer.write("type: .\(shape.type),")
            let relevantTraitIDs = shape.traits.traitDict.keys.filter { allSupportedTraits.contains($0) }
            let traitIDs = Array(relevantTraitIDs).smithySorted()
            if !traitIDs.isEmpty {
                writer.openBlock("traits: [", "],") { writer in
                    for traitID in traitIDs {
                        let trait = shape.traits.traitDict[traitID]!
                        writer.write("\(traitID.rendered): \(trait.rendered),")
                    }
                }
            }
            let members = try (shape as? HasMembers)?.members ?? []
            if !members.isEmpty {
                try writer.openBlock("members: [", "],") { writer in
                    for (index, member) in members.enumerated() {
                        try writeSchema(writer: writer, shape: member, index: index)
                    }
                }
            }
            if let member = shape as? MemberShape {
                let target = try member.target

                // If this schema's target is the same as itself, target the duplicate
                // (see above) to avoid a self-reference compile warning.
                let prefix = target.id == member.containerID ? "dup_of_" : ""
                writer.write(try "target: \(prefix)\(target.schemaVarName),")
            }
            if let index {
                writer.write("index: \(index),")
            }
            writer.unwrite(",")
        }
    }
}

extension ShapeID {

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
