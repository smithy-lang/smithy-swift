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
            let schemaVarName = try shape.schemaVarName
            let swiftType = try ctx.symbolProvider.swiftType(shape: shape)
            writer.write("@_spi(SchemaBasedSerde)")
            try writer.openBlock("extension \(swiftType): SmithySerialization.SerializableStruct {", "}") { writer in
                writer.write("")
                try writer.openBlock(
                    "public func serialize(_ serializer: any SmithySerialization.ShapeSerializer) throws {",
                    "}"
                ) { writer in
                    writer.write("try serializer.writeStruct(\(schemaVarName), self)")
                }
                writer.write("")
                try writer.openBlock(
                    "public func serializeMembers(_ schema: Smithy.Schema, _ serializer: any SmithySerialization.ShapeSerializer) throws {",
                    "}"
                ) { writer in
                    let members = try members(of: shape)
                    if shape.type == .structure {
                        for (index, member) in members.enumerated() {
                            let propertyName = try ctx.symbolProvider.propertyName(shapeID: member.id)
                            let properties = shape.hasTrait(ErrorTrait.self) ? "properties." : ""
                            if try NullableIndex().isNonOptional(member) {
                                try writer.openBlock("do {", "}") { writer in
                                    writer.write("let value = self.\(properties)\(propertyName)")
                                    try writeSerializeCall(
                                        writer: writer, shape: shape, member: member, schemaVarName: "schema.members[\(index)]"
                                    )
                                }
                            } else {
                                try writer.openBlock("if let value = self.\(properties)\(propertyName) {", "}") { writer in
                                    try writeSerializeCall(
                                        writer: writer, shape: shape, member: member, schemaVarName: "schema.members[\(index)]"
                                    )
                                }
                            }
                        }
                    } else /* shape is a union */ {
                        writer.write("switch self {")
                        for (index, member) in members.enumerated() {
                            // Event stream errors don't have a case in the Swift union, so don't try to
                            // serialize the error member
                            if try shape.hasTrait(StreamingTrait.self) && member.target.hasTrait(ErrorTrait.self) {
                                continue
                            }
                            let enumCaseName = try ctx.symbolProvider.enumCaseName(shapeID: member.id)
                            writer.write("case .\(enumCaseName)(let value):")
                            writer.indent()
                            try writeSerializeCall(
                                writer: writer, shape: shape, member: member, schemaVarName: "schema.members[\(index)]"
                            )
                            writer.dedent()
                        }
                        writer.write("default:")
                        writer.indent()
                        writer.write("break")
                        writer.dedent()
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
            let isSparse = listShape.hasTrait(SparseTrait.self)
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
            guard let mapShape = target as? MapShape else {
                throw ModelError("Shape \(target.id) is type .map but not a MapShape")
            }
            let isSparse = mapShape.hasTrait(SparseTrait.self)
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
            let methodName = try target.serializeMethodName
            writer.write("try serializer.\(methodName)(\(schemaVarName), value)")
        }
    }

    private func members(of shape: Shape) throws -> [MemberShape] {
        guard let hasMembers = shape as? HasMembers else { return [] }
        return try hasMembers.members
    }
}
