//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID
import let SmithySerialization.permittedTraitIDs

package struct SmithySchemaCodegen {

    package init() {}

    package func generate(ctx: GenerationContext) throws -> String {
        let writer = SwiftWriter()
        writer.write("import class Smithy.Schema")
        writer.write("import enum Smithy.Prelude")
        writer.write("")

        // Write schemas for all inputs & outputs and their descendants.
        let shapes = try ctx.model.shapes.values
            .filter { $0.type == .structure }
            .filter {
                try $0.hasTrait(try .init("smithy.api#input")) ||
                $0.hasTrait(try .init("smithy.api#output")) ||
                $0.hasTrait(try .init("smithy.api#error"))}
            .map { try [$0] + $0.descendants }
            .flatMap { $0 }
            .filter { $0.type != .member }
            .filter { $0.id.namespace != "smithy.api" }
        let sortedShapes = Array(Set(shapes)).sorted { $0.id.id.lowercased() < $1.id.id.lowercased() }
        writer.write("// Number of schemas: \(sortedShapes.count)")
        writer.write("")
        for shape in sortedShapes {
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
            let relevantTraitIDs = shape.traits.keys.filter { permittedTraitIDs.contains($0.id) }
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
