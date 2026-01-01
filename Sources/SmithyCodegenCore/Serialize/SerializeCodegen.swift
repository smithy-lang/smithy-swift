//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

package struct SerializeCodegen {

    package init() {}

    package func generate(ctx: GenerationContext) throws -> String {
        let writer = SwiftWriter()
        writer.write("import enum Smithy.Prelude")
        writer.write("import class Smithy.Schema")
        writer.write("import protocol SmithySerialization.SerializableStruct")
        writer.write("import protocol SmithySerialization.ShapeSerializer")
        writer.write("import typealias SmithySerialization.WriteStructConsumer")
        writer.write("")

        let structsAndUnions = ctx.model.allShapesSorted.filter { $0.type == .structure || $0.type == .union }
        for shape in structsAndUnions {
            let swiftType = try ctx.symbolProvider.swiftType(shape: shape)
            let varName = shape.type == .structure ? "structure" : "union"
            try writer.openBlock("extension \(swiftType): SmithySerialization.SerializableStruct {", "}") { writer in
                writer.write("")
                writer.write("public static var schema: Smithy.Schema { \(try shape.schemaVarName) }")
                writer.write("")
                try writer.openBlock(
                    "public static var writeConsumer: SmithySerialization.WriteStructConsumer<Self> {", "}"
                ) { writer in
                    try writer.openBlock("{ memberSchema, \(varName), serializer in", "}") { writer in
                        writer.write("switch memberSchema.index {")
                        for (index, member) in try members(of: shape).enumerated() {
                            writer.write("case \(index):")
                            writer.indent()
                            if shape.type == .structure {
                                let propertyName = try ctx.symbolProvider.propertyName(shapeID: member.id)
                                let properties = shape.hasTrait(.init("smithy.api", "error")) ? "properties." : ""
                                writer.write("guard let value = \(varName).\(properties)\(propertyName) else { break }")
                                try writeSerializeCall(
                                    writer: writer, shape: shape, member: member, accessor: "members[\(index)]"
                                )
                            } else { // shape is a union
                                let enumCaseName = try ctx.symbolProvider.enumCaseName(shapeID: member.id)
                                writer.write("guard case .\(enumCaseName)(let value) = \(varName) else { break }")
                                try writeSerializeCall(
                                    writer: writer, shape: shape, member: member, accessor: "members[\(index)]"
                                )
                            }
                            writer.dedent()
                        }
                        writer.write("default: break")
                        writer.write("}")
                    }
                }
            }
            writer.write("")
        }
        writer.unwrite("\n")
        return writer.finalize()
    }

    private func writeSerializeCall(writer: SwiftWriter, shape: Shape, member: MemberShape, accessor: String) throws {
        switch try member.target.type {
        case .list:
            let listShape = try member.target as! ListShape // swiftlint:disable:this force_cast
            let schemaVarName = try shape.schemaVarName
            try writer.openBlock(
                "try serializer.writeList(\(schemaVarName).\(accessor), value) { value, serializer in",
                "}"
            ) { writer in
                try writeSerializeCall(writer: writer, shape: listShape, member: listShape.member, accessor: "member")
            }
        case .map:
            let mapShape = try member.target as! MapShape // swiftlint:disable:this force_cast
            let schemaVarName = try shape.schemaVarName
            try writer.openBlock(
                "try serializer.writeMap(\(schemaVarName).\(accessor), value) { value, serializer in",
                "}"
            ) { writer in
                try writeSerializeCall(writer: writer, shape: mapShape, member: mapShape.value, accessor: "value")
            }
        default:
            let methodName = try member.target.serializeMethodName
            let schemaVarName = try shape.schemaVarName
            writer.write("try serializer.\(methodName)(\(schemaVarName).\(accessor), value)")
        }
    }

    private func members(of shape: Shape) throws -> [MemberShape] {
        guard let hasMembers = shape as? HasMembers else { return [] }
        return try hasMembers.members
    }
}
