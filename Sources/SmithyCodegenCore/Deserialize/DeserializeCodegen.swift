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
        writer.write("import protocol SmithySerialization.DeserializableShape")
        writer.write("")

        let structsAndUnions = ctx.model.allShapesSorted.filter { $0.type == .structure || $0.type == .union }
        for shape in structsAndUnions {
            let swiftType = try ctx.symbolProvider.swiftType(shape: shape)
            try writer.openBlock("extension \(swiftType): SmithySerialization.DeserializableShape {", "}") { writer in
                writer.write("")
                try writer.openBlock(
                    "public mutating func deserialize(_ deserializer: any SmithySerialization.ShapeDeserializer) throws {", "}"
                ) { writer in
                    try writer.openBlock("try deserializer.readStruct(Self.schema) { (memberSchema, deserializer) in", "}") { writer in
                        try writer.openBlock("switch memberSchema.index {", "}") { writer in
                            writer.dedent()
                            for (index, member) in members(of: shape).enumerated() {
                                writer.write("case \(index):")
                                writer.indent()
                                try writeDeserializeCall(ctx: ctx, writer: writer, shape: shape, member: member, index: index)
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

    private func writeDeserializeCall(ctx: GenerationContext, writer: SwiftWriter, shape: Shape, member: MemberShape, index: Int) throws {
        switch member.target.type {
        case .structure:
            let target = member.target
            let propertySwiftType = try ctx.symbolProvider.swiftType(shape: target)
            writer.write("var value = \(propertySwiftType)()")
            writer.write("try value.deserialize(deserializer)")
            try writeAssignment(ctx: ctx, writer: writer, shape: shape, member: member)
        case .union:
            let target = member.target
            let propertySwiftType = try ctx.symbolProvider.swiftType(shape: target)
            writer.write("var value = \(propertySwiftType).sdkUnknown(\"\")")
            writer.write("try value.deserialize(deserializer)")
            try writeAssignment(ctx: ctx, writer: writer, shape: shape, member: member)
        case .list, .set:
            let listShape = member.target as! ListShape
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
            let mapShape = member.target as! MapShape
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
                "self.\(properties)\(propertyName) = "
            }
            writer.write("\(lhs)try deserializer.\(methodName)(\(schemaVarName).members[\(index)])")
        }
    }

    private func writeAssignment(ctx: GenerationContext, writer: SwiftWriter, shape: Shape, member: MemberShape) throws {
        guard [.structure, .list, .set, .map].contains(member.target.type) else { return }
        switch shape.type {
        case .structure:
            let properties = shape.hasTrait(.init("smithy.api", "error")) ? "properties." : ""
            let propertyName = try ctx.symbolProvider.propertyName(shapeID: member.id)
            writer.write("self.\(properties)\(propertyName) = value")
        case .union:
            let enumCaseName = try ctx.symbolProvider.enumCaseName(shapeID: member.id)
            writer.write("self = .\(enumCaseName)(value)")
        case .list, .set, .map:
            writer.write("return value")
        default: break
        }
    }

    private func members(of shape: Shape) -> [MemberShape] {
        guard let hasMembers = shape as? HasMembers else { return [] }
        return hasMembers.members
    }
}
