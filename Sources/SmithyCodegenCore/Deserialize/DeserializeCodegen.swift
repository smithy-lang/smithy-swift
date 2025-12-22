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
        writer.write("import protocol SmithySerialization.ShapeDeserializer")
        writer.write("import protocol SmithySerialization.DeserializableStruct")
        writer.write("import typealias SmithySerialization.StructMemberConsumer")
        writer.write("")

        let structsAndUnions = ctx.model.allShapesSorted.filter { $0.type == .structure || $0.type == .union }
        for shape in structsAndUnions {
            let swiftType = try ctx.symbolProvider.swiftType(shape: shape)
            try writer.openBlock("extension \(swiftType): SmithySerialization.DeserializableStruct {", "}") { writer in
                writer.write("")
                let consumerType = "SmithySerialization.StructMemberConsumer<\(swiftType)>"
                try writer.openBlock(
                    "public static var consumer: \(consumerType) {", "}") { writer in
                    try writer.openBlock("{ memberSchema, structure, deserializer in", "}") { writer in
                        try writer.openBlock("switch memberSchema.index {", "}") { writer in
                            writer.dedent()
                            for (index, member) in members(of: shape).enumerated() {
                                writer.write("case \(index):")
                                writer.indent()
                                try writeDeserializeCall(
                                    ctx: ctx, writer: writer, shape: shape, member: member, index: index
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
                    "public mutating func deserialize(_ deserializer: \(deserializerType)) throws {", "}"
                ) { writer in
                    writer.write("var value = self")
                    writer.write("try deserializer.readStruct(Self.schema, &value, Self.consumer)")
                    writer.write("self = value")
                }
            }
            writer.write("")
        }
        writer.unwrite("\n")
        return writer.finalize()
    }

    private func writeDeserializeCall(
        ctx: GenerationContext, writer: SwiftWriter, shape: Shape, member: MemberShape, index: Int
    ) throws {
        switch member.target.type {
        case .structure:
            try writeStructureDeserializeCall(
                ctx: ctx, writer: writer, shape: shape, member: member, index: index, initializer: "()"
            )
        case .union:
            try writeStructureDeserializeCall(
                ctx: ctx, writer: writer, shape: shape, member: member, index: index, initializer: ".sdkUnknown(\"\")"
            )
        case .list, .set:
            let listShape = member.target as! ListShape // swiftlint:disable:this force_cast
            let elementSwiftType = try ctx.symbolProvider.swiftType(shape: listShape.member.target)
            writer.write("var value = [\(elementSwiftType)]()")
            let schemaVarName = try shape.schemaVarName
            try writer.openBlock(
                "try deserializer.readList(\(schemaVarName).members[\(index)], &value) { deserializer in",
                "}"
            ) { writer in
                try writeDeserializeCall(ctx: ctx, writer: writer, shape: listShape, member: listShape.member, index: 0)
            }
            try writeAssignment(ctx: ctx, writer: writer, shape: shape, member: member)
        case .map:
            let mapShape = member.target as! MapShape // swiftlint:disable:this force_cast
            let keySwiftType = try ctx.symbolProvider.swiftType(shape: mapShape.key.target)
            let valueSwiftType = try ctx.symbolProvider.swiftType(shape: mapShape.value.target)
            writer.write("var value = [\(keySwiftType): \(valueSwiftType)]()")
            let schemaVarName = try shape.schemaVarName
            try writer.openBlock(
                "try deserializer.readMap(\(schemaVarName).members[\(index)], &value) { key, deserializer in",
                "}"
            ) { writer in
                try writeDeserializeCall(ctx: ctx, writer: writer, shape: mapShape, member: mapShape.value, index: 1)
            }
            try writeAssignment(ctx: ctx, writer: writer, shape: shape, member: member)
        default:
            let propertyName = try ctx.symbolProvider.propertyName(shapeID: member.id)
            let methodName = try member.target.deserializeMethodName
            let schemaVarName = try shape.schemaVarName
            let properties = shape.hasTrait(.init("smithy.api", "error")) ? "properties." : ""
            let lhs = switch shape.type {
            case .list, .set, .map:
                ""
            default:
                "structure.\(properties)\(propertyName) = "
            }
            writer.write("\(lhs)try deserializer.\(methodName)(\(schemaVarName).members[\(index)])")
        }
    }

    private func writeStructureDeserializeCall(
        ctx: GenerationContext, writer: SwiftWriter, shape: Shape, member: MemberShape, index: Int, initializer: String
    ) throws {
        let target = member.target
        let propertySwiftType = try ctx.symbolProvider.swiftType(shape: target)
        let schemaVarName = try shape.schemaVarName
        let consumer = "\(propertySwiftType).consumer"
        writer.write("var value = \(propertySwiftType)\(initializer)")
        writer.write("try deserializer.readStruct(\(schemaVarName).members[\(index)], &value, \(consumer))")
        try writeAssignment(ctx: ctx, writer: writer, shape: shape, member: member)
    }

    private func writeAssignment(
        ctx: GenerationContext, writer: SwiftWriter, shape: Shape, member: MemberShape
    ) throws {
        // Only the "composite types" need to have an assignment written.
        guard [.structure, .union, .list, .set, .map].contains(member.target.type) else { return }

        // The assignment being written is based on the shape enclosing the member.
        switch shape.type {
        case .structure:
            // For a structure member, write the value to the appropriate structure property,
            // making the appropriate adjustment for an error.
            let properties = shape.hasTrait(.init("smithy.api", "error")) ? "properties." : ""
            let propertyName = try ctx.symbolProvider.propertyName(shapeID: member.id)
            writer.write("structure.\(properties)\(propertyName) = value")
        case .union:
            // For a union member, write the value to the appropriate union case
            let enumCaseName = try ctx.symbolProvider.enumCaseName(shapeID: member.id)
            writer.write("structure = .\(enumCaseName)(value)")
        case .list, .set, .map:
            // For a collection member, return it to the caller since this is being written
            // into a consumer block that returns the collection element.
            writer.write("return value")
        default: break
        }
    }

    private func members(of shape: Shape) -> [MemberShape] {
        guard let hasMembers = shape as? HasMembers else { return [] }
        return hasMembers.members
    }
}
