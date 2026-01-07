//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

package struct DeserializeCodegen {

    package init() {}

    private func schemaNotDefinedBySerialize(shape: Shape, inputShapes: Set<Shape>) throws -> Bool {
        if let inputShape = inputShapes.first(where: { $0.id == shape.id }) {
            return inputShape.hasTrait(.init("smithy.api", "input"))
        } else {
            return true
        }
    }

    package func generate(ctx: GenerationContext) throws -> String {
        let writer = SwiftWriter()
        writer.write("import Foundation")
        writer.write("import enum Smithy.Prelude")
        writer.write("import class Smithy.Schema")
        writer.write("import protocol SmithySerialization.DeserializableStruct")
        writer.write("import typealias SmithySerialization.ReadStructConsumer")
        writer.write("import protocol SmithySerialization.ShapeDeserializer")
        writer.write("")

        let service = try ctx.model.expectShape(id: ctx.serviceID) as! ServiceShape
        let outputStructsAndUnions = try service
            .outputDescendants
            .filter { $0.type == .structure || $0.type == .union }
            .sorted { $0.id.id.lowercased() < $1.id.id.lowercased() }
        let inputStructsAndUnions = try service
            .inputDescendants
            .filter { $0.type == .structure || $0.type == .union }
        for shape in outputStructsAndUnions {
            let swiftType = try ctx.symbolProvider.outputSwiftType(shape: shape)
            let varName = shape.type == .structure ? "structure" : "union"
            try writer.openBlock("extension \(swiftType): SmithySerialization.DeserializableStruct {", "}") { writer in
                writer.write("")
                if try schemaNotDefinedBySerialize(shape: shape, inputShapes: inputStructsAndUnions) {
                    writer.write("public static var schema: Smithy.Schema { \(try shape.schemaVarName) }")
                    writer.write("")
                }
                let consumerType = "SmithySerialization.ReadStructConsumer<Self>"
                try writer.openBlock(
                    "public static var readConsumer: \(consumerType) {", "}") { writer in
                    try writer.openBlock("{ memberSchema, \(varName), deserializer in", "}") { writer in
                        try writer.openBlock("switch memberSchema.index {", "}") { writer in
                            writer.dedent()
                            for (index, member) in try members(of: shape).enumerated() {
                                writer.write("case \(index):")
                                writer.indent()
                                try writeDeserializeCall(
                                    ctx: ctx, writer: writer, shape: shape, member: member, index: index, varName: varName, schemaRef: "memberSchema"
                                )
                                writer.dedent()
                            }
                            writer.write("default: break")
                            writer.indent()
                        }
                    }
                }
                writer.write("")
                let deserializerType = "any SmithySerialization.ShapeDeserializer"
                writer.openBlock(
                    "public static func deserialize(_ deserializer: \(deserializerType)) throws -> Self {", "}"
                ) { writer in
                    let initializer = shape.type == .structure ? "()" : ".sdkUnknown(\"\")"
                    writer.write("var value = Self\(initializer)")
                    writer.write("try deserializer.readStruct(Self.schema, &value)")
                    writer.write("return value")
                }
            }
            writer.write("")
        }
        writer.unwrite("\n")
        return writer.finalize()
    }

    private func writeDeserializeCall(
        ctx: GenerationContext, writer: SwiftWriter, shape: Shape, member: MemberShape, index: Int, varName: String, schemaRef: String? = nil
    ) throws {
        let schemaVarName = try schemaRef ?? "\(shape.schemaVarName).members[\(index)]"
        switch try member.target.type {
        case .structure:
            try writeStructureDeserializeCall(
                ctx: ctx, writer: writer, shape: shape, member: member, index: index, initializer: "()", varName: varName, schemaVarName: schemaVarName
            )
        case .union:
            try writeStructureDeserializeCall(
                ctx: ctx, writer: writer, shape: shape, member: member, index: index, initializer: ".sdkUnknown(\"\")", varName: varName, schemaVarName: schemaVarName
            )
        case .list, .set:
            guard let listShape = try member.target as? ListShape else {
                throw SymbolProviderError("Shape has type .list but is not a ListShape")
            }
            let listSwiftType = try ctx.symbolProvider.swiftType(shape: listShape)
            let isSparse = listShape.hasTrait(.init("smithy.api", "sparse"))
            let methodName = isSparse ? "readSparseList" : "readList"
            writer.write("var value = \(listSwiftType)()")
            try writer.openBlock(
                "try deserializer.\(methodName)(\(schemaVarName), &value) { deserializer in",
                "}"
            ) { writer in
                try writeDeserializeCall(ctx: ctx, writer: writer, shape: listShape, member: listShape.member, index: 0, varName: varName, schemaRef: "\(schemaVarName).target!.member")
            }
            try writeAssignment(ctx: ctx, writer: writer, shape: shape, member: member, varName: varName)
        case .map:
            guard let mapShape = try member.target as? MapShape else {
                throw SymbolProviderError("Shape has type .map but is not a MapShape")
            }
            let mapSwiftType = try ctx.symbolProvider.swiftType(shape: mapShape)
            let isSparse = mapShape.hasTrait(.init("smithy.api", "sparse"))
            let methodName = isSparse ? "readSparseMap" : "readMap"
            writer.write("var value = \(mapSwiftType)()")
            try writer.openBlock(
                "try deserializer.\(methodName)(\(schemaVarName), &value) { deserializer in",
                "}"
            ) { writer in
                try writeDeserializeCall(ctx: ctx, writer: writer, shape: mapShape, member: mapShape.value, index: 1, varName: varName, schemaRef: "\(schemaVarName).target!.value")
            }
            try writeAssignment(ctx: ctx, writer: writer, shape: shape, member: member, varName: varName)
        default:
            let propertyName = try ctx.symbolProvider.propertyName(shapeID: member.id)
            let methodName = try member.target.deserializeMethodName
            let properties = shape.hasTrait(.init("smithy.api", "error")) ? "properties." : ""
            let lhs = switch shape.type {
            case .list, .set, .map:
                "return "
            default:
                "structure.\(properties)\(propertyName) = "
            }
            writer.write("\(lhs)try deserializer.\(methodName)(\(schemaVarName))")
        }
    }

    private func writeStructureDeserializeCall(
        ctx: GenerationContext, writer: SwiftWriter, shape: Shape, member: MemberShape, index: Int, initializer: String, varName: String, schemaVarName: String
    ) throws {
        let target = try member.target
        let propertySwiftType = try ctx.symbolProvider.swiftType(shape: target)
        writer.write("var value = \(propertySwiftType)\(initializer)")
        writer.write("try deserializer.readStruct(\(schemaVarName), &value)")
        try writeAssignment(ctx: ctx, writer: writer, shape: shape, member: member, varName: varName)
    }

    private func writeAssignment(
        ctx: GenerationContext, writer: SwiftWriter, shape: Shape, member: MemberShape, varName: String
    ) throws {
        // Only the "composite types" need to have an assignment written.
        guard try [.structure, .union, .list, .set, .map].contains(member.target.type) else { return }

        // The assignment being written is based on the shape enclosing the member.
        switch shape.type {
        case .structure:
            // For a structure member, write the value to the appropriate structure property,
            // making the appropriate adjustment for an error.
            let properties = shape.hasTrait(.init("smithy.api", "error")) ? "properties." : ""
            let propertyName = try ctx.symbolProvider.propertyName(shapeID: member.id)
            writer.write("\(varName).\(properties)\(propertyName) = value")
        case .union:
            // For a union member, write the value to the appropriate union case
            let enumCaseName = try ctx.symbolProvider.enumCaseName(shapeID: member.id)
            writer.write("\(varName) = .\(enumCaseName)(value)")
        case .list, .set, .map:
            // For a collection member, return it to the caller since this is being written
            // into a consumer block that returns the collection element.
            writer.write("return value")
        default: break
        }
    }

    private func members(of shape: Shape) throws -> [MemberShape] {
        guard let hasMembers = shape as? HasMembers else { return [] }
        return try hasMembers.members
    }
}
