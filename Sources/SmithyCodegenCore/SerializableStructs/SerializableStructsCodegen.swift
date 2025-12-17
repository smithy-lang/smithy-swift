//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

package struct SerializableStructsCodegen {

    package init() {}
    
    package func generate(ctx: GenerationContext) throws -> String {
        let writer = SwiftWriter()
        writer.write("import enum Smithy.Prelude")
        writer.write("import class Smithy.Schema")
        writer.write("import protocol SmithySerialization.SerializableStruct")
        writer.write("import protocol SmithySerialization.ShapeSerializer")
        writer.write("")

        for shape in ctx.model.shapes.values where shape.type == .structure || shape.type == .union {
            let swiftType = try ctx.symbolProvider.swiftType(shape: shape)
            try writer.openBlock("extension \(swiftType): SmithySerialization.SerializableStruct {", "}") { writer in
                writer.write("")
                writer.write("public static var schema: Smithy.Schema { \(try shape.schemaVarName) }")
                writer.write("")
                try writer.openBlock(
                    "public func serializeMembers(_ serializer: any SmithySerialization.ShapeSerializer) {", "}"
                ) { writer in
                    for (index, member) in members(of: shape).enumerated() {
                        if shape.type == .structure {
                            let propertyName = try ctx.symbolProvider.propertyName(shapeID: member.id)
                            let properties = shape.hasTrait(.init("smithy.api", "error")) ? "properties." : ""
                            try writer.openBlock("if let value = self.\(properties)\(propertyName) {", "}") { writer in
                                try writeSerializeCall(writer: writer, shape: shape, member: member, index: index)
                            }
                        } else { // shape is a union
                            let enumCaseName = try ctx.symbolProvider.enumCaseName(shapeID: member.id)
                            try writer.openBlock("if case .\(enumCaseName)(let value) = self {", "}") { writer in
                                try writeSerializeCall(writer: writer, shape: shape, member: member, index: index)
                            }
                        }
                    }
                }
            }
            writer.write("")
        }
        writer.unwrite("\n")
        return writer.finalize()
    }

    private func writeSerializeCall(writer: SwiftWriter, shape: Shape, member: MemberShape, index: Int) throws {
        switch member.target.type {
        case .list:
            writer.write("// serialize list here")
        case .map:
            writer.write("// serialize map here")
        default:
            let methodName = try member.target.structConsumerMethod
            let schemaVarName = try shape.schemaVarName
            writer.write("serializer.\(methodName)(schema: \(schemaVarName).members[\(index)], value: value)")
        }
    }

    private func members(of shape: Shape) -> [MemberShape] {
        guard let hasMembers = shape as? HasMembers else { return [] }
        return hasMembers.members
    }
}
