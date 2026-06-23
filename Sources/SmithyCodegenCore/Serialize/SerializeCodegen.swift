//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import struct Smithy.ErrorTrait
@_spi(SchemaBasedSerde)
import struct Smithy.SparseTrait
@_spi(SchemaBasedSerde)
import struct Smithy.StreamingTrait

package struct SerializeCodegen {

    package init() {}

    package func generate(ctx: GenerationContext) throws -> String {
        let writer = SwiftWriter()
        writer.write("import Foundation")
        writer.write("@_spi(SchemaBasedSerde)")
        writer.write("import Smithy")
        writer.write("@_spi(SchemaBasedSerde)")
        writer.write("import SmithySerialization")
        writer.write("")

        // Must generate SerializableStruct conformance for all of a service's
        // structs & unions, not just those that are serialized as part of operation
        // inputs, so that all structs & unions get the CustomDebugStringConvertible
        // conformance that hides sensitive data
        let serviceStructsAndUnions = try ctx.service.descendants
            .filter { $0.type == .structure || $0.type == .union }
            .smithySorted()

        for shape in serviceStructsAndUnions {
            let swiftType = try ctx.symbolProvider.swiftType(shape: shape)
            let varName = shape.type == .structure ? "structure" : "union"
            writer.write("@_spi(SchemaBasedSerde)")
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
                    let paramSwiftType = try ctx.symbolProvider.swiftType(shape: shape, forParamUse: true)
                    try writer.openBlock("{ (memberSchema: Smithy.Schema, \(varName): \(paramSwiftType), " +
                                            "serializer: any SmithySerialization.ShapeSerializer) throws -> Void in",
                                         "}") { writer in
                        writer.write("switch memberSchema.index {")
                        for (index, member) in try members(of: shape).enumerated() {

                            // Event stream errors don't have a case in the Swift union, so don't try to
                            // serialize the error member
                            if try shape.hasTrait(StreamingTrait.self) && member.target.hasTrait(ErrorTrait.self) {
                                continue
                            }
                            writer.write("case \(index):")
                            writer.indent()
                            if shape.type == .structure {
                                let propertyName = try ctx.symbolProvider.propertyName(shapeID: member.id)
                                let properties = shape.hasTrait(ErrorTrait.self) ? "properties." : ""
                                if try NullableIndex().isNonOptional(member) {
                                    writer.write("let value = \(varName).\(properties)\(propertyName)")
                                } else {
                                    writer.write(
                                        "guard let value = \(varName).\(properties)\(propertyName) else { break }"
                                    )
                                }
                                try writeSerializeCall(
                                    ctx: ctx,
                                    writer: writer,
                                    shape: shape,
                                    member: member,
                                    schemaVarName: "memberSchema"
                                )
                            } else { // shape is a union
                                let enumCaseName = try ctx.symbolProvider.enumCaseName(shapeID: member.id)
                                writer.write("guard case .\(enumCaseName)(let value) = \(varName) else { break }")
                                try writeSerializeCall(
                                    ctx: ctx,
                                    writer: writer,
                                    shape: shape,
                                    member: member,
                                    schemaVarName: "memberSchema"
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
        return writer.contents
    }

    private func writeSerializeCall(
        ctx: GenerationContext,
        writer: SwiftWriter,
        shape: Shape,
        member: MemberShape,
        schemaVarName: String
    ) throws {
        let target = try member.target
        switch target.type {
        case .list, .set:
            guard let listShape = target as? ListShape else {
                throw ModelError("Shape \(target.id) is type .\(target.type) but not a ListShape")
            }
            let listMemberSwiftType = try ctx.symbolProvider.swiftType(shape: listShape.member.target)
            let isSparse = listShape.hasTrait(SparseTrait.self)
            let methodName = isSparse ? "writeSparseList" : "writeList"
            try writer.openBlock(
                "try serializer.\(methodName)(\(schemaVarName), value) { (value: \(listMemberSwiftType), serializer: " +
                "any SmithySerialization.ShapeSerializer) throws -> Void in",
                "}"
            ) { writer in
                try writeSerializeCall(
                    ctx: ctx,
                    writer: writer,
                    shape: listShape,
                    member: listShape.member,
                    schemaVarName: "\(schemaVarName).target!.member"
                )
            }
        case .map:
            guard let mapShape = target as? MapShape else {
                throw ModelError("Shape \(target.id) is type .map but not a MapShape")
            }
            let mapValueSwiftType = try ctx.symbolProvider.swiftType(shape: mapShape.value.target)
            let isSparse = mapShape.hasTrait(SparseTrait.self)
            let methodName = isSparse ? "writeSparseMap" : "writeMap"
            try writer.openBlock(
                "try serializer.\(methodName)(\(schemaVarName), value) { (value: \(mapValueSwiftType), " +
                "serializer: any SmithySerialization.ShapeSerializer) throws -> Void in",
                "}"
            ) { writer in
                try writeSerializeCall(
                    ctx: ctx,
                    writer: writer,
                    shape: mapShape,
                    member: mapShape.value,
                    schemaVarName: "\(schemaVarName).target!.value"
                )
            }
        default:
            let methodName = try target.serializeMethodName
            writer.write("try serializer.\(methodName)(\(schemaVarName), value)")
        }
    }

    private func members(of shape: Shape) throws -> [MemberShape] {
        guard let hasMembers = shape as? HasMembers else { return [] }
        return try hasMembers.members
    }
}
