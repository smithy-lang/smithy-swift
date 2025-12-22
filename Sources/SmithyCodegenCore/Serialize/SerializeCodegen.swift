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
        writer.write("")

        let structsAndUnions = ctx.model.allShapesSorted.filter { $0.type == .structure || $0.type == .union }
        for shape in structsAndUnions {
            let swiftType = try ctx.symbolProvider.swiftType(shape: shape)
            try writer.openBlock("extension \(swiftType): SmithySerialization.SerializableStruct {", "}") { writer in
                writer.write("")
                writer.write("public static var schema: Smithy.Schema { \(try shape.schemaVarName) }")
                writer.write("")
                try writer.openBlock(
                    "public func serializeMembers(_ serializer: any SmithySerialization.ShapeSerializer) throws {", "}"
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
            let listShape = member.target as! ListShape // swiftlint:disable:this force_cast
            let schemaVarName = try shape.schemaVarName
            try writer.openBlock(
                "try serializer.writeList(\(schemaVarName).members[\(index)], value.count) { serializer in",
                "}"
            ) { writer in
                try writer.openBlock("for value in value {", "}") { writer in
                    try writeSerializeCall(writer: writer, shape: listShape, member: listShape.member, index: 0)
                }
            }
        case .map:
            let mapShape = member.target as! MapShape // swiftlint:disable:this force_cast
            let schemaVarName = try shape.schemaVarName
            try writer.openBlock(
                "try serializer.writeMap(\(schemaVarName).members[\(index)], value.count) { mapSerializer in",
                "}"
            ) { writer in
                try writer.openBlock("for (key, value) in value {", "}") { writer in
                    let schemaVarName = try mapShape.schemaVarName
                    let schema = "\(schemaVarName).members[0]"
                    try writer.openBlock(
                        "try mapSerializer.writeEntry(\(schema), key) { serializer in",
                        "}"
                    ) { writer in
                        try writeSerializeCall(writer: writer, shape: mapShape, member: mapShape.value, index: 1)
                    }
                }
            }
        default:
            let methodName = try member.target.serializeMethodName
            let schemaVarName = try shape.schemaVarName
            writer.write("try serializer.\(methodName)(\(schemaVarName).members[\(index)], value)")
        }
    }

    private func members(of shape: Shape) -> [MemberShape] {
        guard let hasMembers = shape as? HasMembers else { return [] }
        return hasMembers.members
    }
}
