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

        // Get the service
        guard let service = try ctx.model.expectShape(id: ctx.serviceID) as? ServiceShape else {
            throw ModelError("Service \"\(ctx.serviceID)\" not found in model")
        }

        let inputStructsAndUnions = try service
            .inputDescendants
            .filter { $0.type == .structure || $0.type == .union }
            .sorted { $0.id.id.lowercased() < $1.id.id.lowercased() }
        for shape in inputStructsAndUnions {
            let swiftType = try ctx.symbolProvider.inputSwiftType(shape: shape)
            let varName = shape.type == .structure ? "structure" : "union"
            try writer.openBlock("extension \(swiftType): SmithySerialization.SerializableStruct {", "}") { writer in
                writer.write("")
                try writer.openBlock(
                    "public func serialize(_ serializer: any SmithySerialization.ShapeSerializer) throws {",
                    "}"
                ) { writer in
                    let schemaVarName = try shape.schemaVarName
                    writer.write("try serializer.writeStruct(\(schemaVarName), self)")
                }
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
                                if try NullableIndex().isNonOptional(member) {
                                    writer.write("let value = \(varName).\(properties)\(propertyName)")
                                } else {
                                    writer.write(
                                        "guard let value = \(varName).\(properties)\(propertyName) else { break }"
                                    )
                                }
                                try writeSerializeCall(
                                    writer: writer, shape: shape, member: member, schemaVarName: "memberSchema"
                                )
                            } else { // shape is a union
                                let enumCaseName = try ctx.symbolProvider.enumCaseName(shapeID: member.id)
                                writer.write("guard case .\(enumCaseName)(let value) = \(varName) else { break }")
                                try writeSerializeCall(
                                    writer: writer, shape: shape, member: member, schemaVarName: "memberSchema"
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

    private func writeSerializeCall(
        writer: SwiftWriter,
        shape: Shape,
        member: MemberShape,
        schemaVarName: String
    ) throws {
        switch try member.target.type {
        case .list:
            let listShape = try member.target as! ListShape // swiftlint:disable:this force_cast
            let isSparse = listShape.hasTrait(.init("smithy.api", "sparse"))
            let methodName = isSparse ? "writeSparseList" : "writeList"
            try writer.openBlock(
                "try serializer.\(methodName)(\(schemaVarName), value) { value, serializer in",
                "}"
            ) { writer in
                try writeSerializeCall(
                    writer: writer,
                    shape: listShape,
                    member: listShape.member,
                    schemaVarName: "\(schemaVarName).target!.member"
                )
            }
        case .map:
            let mapShape = try member.target as! MapShape // swiftlint:disable:this force_cast
            let isSparse = mapShape.hasTrait(.init("smithy.api", "sparse"))
            let methodName = isSparse ? "writeSparseMap" : "writeMap"
            try writer.openBlock(
                "try serializer.\(methodName)(\(schemaVarName), value) { value, serializer in",
                "}"
            ) { writer in
                try writeSerializeCall(
                    writer: writer,
                    shape: mapShape,
                    member: mapShape.value,
                    schemaVarName: "\(schemaVarName).target!.value"
                )
            }
        default:
            let methodName = try member.target.serializeMethodName
            writer.write("try serializer.\(methodName)(\(schemaVarName), value)")
        }
    }

    private func members(of shape: Shape) throws -> [MemberShape] {
        guard let hasMembers = shape as? HasMembers else { return [] }
        return try hasMembers.members
    }
}
