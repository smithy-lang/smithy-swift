//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct OperationsCodegen {

    func generate(ctx: GenerationContext) throws -> String {
        let writer = SwiftWriter()
        writer.write("import Smithy")
        writer.write("import SmithySerialization")
        writer.write("")

        let sortedOperations = ctx.model.allShapesSorted
            .filter { $0.type == .operation }
            .compactMap { $0 as? OperationShape }

        let clientSymbol = try ctx.symbolProvider.swiftType(shape: ctx.service)

        try writer.openBlock("public extension \(clientSymbol) {", "}") { writer in
            for operation in sortedOperations {
                writer.write("")
                let varName = "\(try ctx.symbolProvider.operationMethodName(operation: operation))Operation"
                let type = "SmithySerialization.Operation"
                let input = try ctx.symbolProvider.swiftType(shape: operation.input)
                let output = try ctx.symbolProvider.swiftType(shape: operation.output)
                try writer.openBlock("static var \(varName): \(type)<\(input), \(output)> {", "}") { writer in
                    try writer.openBlock(".init(", ")") { writer in
                        writer.write("schema: \(try operation.schemaVarName),")
                        writer.write("serviceSchema: \(try ctx.service.schemaVarName),")
                        writer.write("inputSchema: \(try operation.input.schemaVarName),")
                        writer.write("outputSchema: \(try operation.output.schemaVarName),")
                        writer.write("errorTypeRegistry: \(clientSymbol).errorTypeRegistry")
                    }
                }
            }
        }
        return writer.finalize()
    }
}
