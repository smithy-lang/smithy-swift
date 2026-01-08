//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

package struct DeserializeCodegen {

    package init() {}

    package func generate(ctx: GenerationContext) throws -> String {
        let writer = SwiftWriter()
        writer.write("import Foundation")
        writer.write("import enum Smithy.Prelude")
        writer.write("import class Smithy.Schema")
        writer.write("import protocol SmithySerialization.DeserializableStruct")
        writer.write("import typealias SmithySerialization.ReadStructConsumer")
        writer.write("import protocol SmithySerialization.ShapeDeserializer")
        writer.write("")

        // Get the service
        guard let service = try ctx.model.expectShape(id: ctx.serviceID) as? ServiceShape else {
            throw ModelError("Service \"\(ctx.serviceID)\" not found in model")
        }

        // Get structs & unions that are part of an operation output.
        // These will all get a DeserializableShape conformance rendered.
        let outputStructsAndUnions = try service
            .outputDescendants
            .filter { $0.type == .structure || $0.type == .union }
            .sorted { $0.id.id.lowercased() < $1.id.id.lowercased() }

        // Render a DeserializableStruct conformance for every struct & union.
        for shape in outputStructsAndUnions {
            let swiftType = try ctx.symbolProvider.outputSwiftType(shape: shape)
            let varName = shape.type == .structure ? "structure" : "union"
            try writer.openBlock("extension \(swiftType): SmithySerialization.DeserializableStruct {", "}") { writer in
                writer.write("")
                let deserializerType = "any SmithySerialization.ShapeDeserializer"
                try writer.openBlock(
                    "public static func deserialize(_ deserializer: \(deserializerType)) throws -> Self {", "}"
                ) { writer in
                    let initializer = shape.type == .structure ? "()" : ".sdkUnknown(\"\")"
                    writer.write("var value = Self\(initializer)")
                    let schemaVarName = try shape.schemaVarName
                    writer.write("try deserializer.readStruct(\(schemaVarName), &value)")
                    writer.write("return value")
                }
                writer.write("")
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
                                    ctx: ctx,
                                    writer: writer,
                                    shape: shape,
                                    member: member,
                                    schemaVarName: "memberSchema"
                                )
                                writer.dedent()
                            }
                            writer.write("default: break")
                            writer.indent()
                        }
                    }
                }
            }
            writer.write("")
        }
        writer.unwrite("\n")
        return writer.finalize()
    }

    private func writeDeserializeCall(
        ctx: GenerationContext,
        writer: SwiftWriter,
        shape: Shape,
        member: MemberShape,
        schemaVarName: String
    ) throws {
        switch try member.target.type {
        case .structure:
            try writeStructureDeserializeCall(
                ctx: ctx,
                writer: writer,
                shape: shape,
                member: member,
                initializer: "()",
                schemaVarName: schemaVarName
            )
        case .union:
            try writeStructureDeserializeCall(
                ctx: ctx,
                writer: writer,
                shape: shape,
                member: member,
                initializer: ".sdkUnknown(\"\")",
                schemaVarName: schemaVarName
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
                try writeDeserializeCall(
                    ctx: ctx,
                    writer: writer,
                    shape: listShape,
                    member: listShape.member,
                    schemaVarName: "\(schemaVarName).target!.member"
                )
            }
            try writeAssignment(ctx: ctx, writer: writer, shape: shape, member: member)
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
                try writeDeserializeCall(
                    ctx: ctx,
                    writer: writer,
                    shape: mapShape,
                    member: mapShape.value,
                    schemaVarName: "\(schemaVarName).target!.value"
                )
            }
            try writeAssignment(ctx: ctx, writer: writer, shape: shape, member: member)
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
        ctx: GenerationContext,
        writer: SwiftWriter,
        shape: Shape,
        member: MemberShape,
        initializer: String,
        schemaVarName: String
    ) throws {
        let target = try member.target
        let propertySwiftType = try ctx.symbolProvider.swiftType(shape: target)
        writer.write("var value = \(propertySwiftType)\(initializer)")
        writer.write("try deserializer.readStruct(\(schemaVarName), &value)")
        try writeAssignment(ctx: ctx, writer: writer, shape: shape, member: member)
    }

    private func writeAssignment(
        ctx: GenerationContext,
        writer: SwiftWriter,
        shape: Shape,
        member: MemberShape
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
            writer.write("structure.\(properties)\(propertyName) = value")
        case .union:
            // For a union member, write the appropriate union case to the union variable
            let enumCaseName = try ctx.symbolProvider.enumCaseName(shapeID: member.id)
            writer.write("union = .\(enumCaseName)(value)")
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
