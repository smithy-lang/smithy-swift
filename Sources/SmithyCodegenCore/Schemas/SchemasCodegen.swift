//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID
import enum Smithy.ShapeType
import let SmithySerialization.permittedTraitIDs

package struct SchemasCodegen {

    package init() {}

    package func generate(ctx: GenerationContext) throws -> String {
        let writer = SwiftWriter()
        writer.write("import class Smithy.Schema")
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
            try writer.openBlock("public var \(shape.schemaVarName): Smithy.Schema {", "}") { writer in
                try writeSchema(writer: writer, shape: shape)
                writer.unwrite(",")
            }
            writer.write("")
        }
        writer.unwrite("\n")
        return writer.finalize()
    }

    private func writeSchema(writer: SwiftWriter, shape: Shape, index: Int? = nil) throws {
        try writer.openBlock(".init(", "),") { writer in
            writer.write("id: \(shape.id.rendered),")
            writer.write("type: .\(shape.type),")
            let relevantTraitIDs = shape.traits.keys.filter { permittedTraitIDs.contains($0.absoluteID) }
            let traitIDs = Array(relevantTraitIDs).sorted()
            if !traitIDs.isEmpty {
                writer.openBlock("traits: [", "],") { writer in
                    for traitID in traitIDs {
                        let trait = shape.traits[traitID]!
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
            if let target = try (shape as? MemberShape)?.target {
                writer.write(try "target: \(target.schemaVarName),")
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
