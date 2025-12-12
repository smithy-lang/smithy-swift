//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

package struct StructConsumersCodegen {
    
    package init() {}
    
    package func generate(model: Model) throws -> String {
        let writer = SwiftWriter()
        writer.write("import enum Smithy.Prelude")
        writer.write("import protocol SmithySerialization.SerializableStruct")
        writer.write("import protocol SmithySerialization.ShapeSerializer")
        writer.write("")

        for shape in model.shapes.values where shape.type == .structure || shape.type == .union {
            let symbolProvider = SymbolProvider(model: model)
            let swiftType = symbolProvider.swiftType(shape: shape)
            let varName = shape.type == .structure ? "structure" : "union"
            writer.openBlock("let \(shape.structConsumerVarName) = { (\(varName): \(swiftType), serializer: any ShapeSerializer) in", "}") { writer in
                for member in shape.members {
                    guard let target = member.target else { fatalError("Member \(member.id) does not have target") }
                    let memberName = symbolProvider.methodName(shapeID: member.id)
                    if shape.type == .structure {
                        let properties = shape.hasTrait(.init("smithy.api", "error")) ? "properties." : ""
                        writer.openBlock("if let value = \(varName).\(properties)\(memberName) {", "}") { writer in
                            writeSerializeCall(writer: writer, target: target)
                        }
                    } else { // shape is a union
                        writer.openBlock("if case .\(memberName)(let value) = \(varName) {", "}") { writer in
                            writeSerializeCall(writer: writer, target: target)
                        }
                    }
                }
            }
            writer.write("")
        }
        writer.unwrite("\n")
        return writer.finalize()
    }

    private func writeSerializeCall(writer: SwiftWriter, target: Shape) {
        switch target.type {
        case .structure, .union:
            writer.write("// serialize struct or union here")
        case .list:
            writer.write("// serialize list here")
        case .map:
            writer.write("// serialize map here")
        default:
            writer.write("serializer.\(target.structConsumerMethod)(schema: \(target.schemaVarName), value: value)")
        }
    }
}
