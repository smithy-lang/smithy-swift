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
        writer.write("@_spi(SchemaBasedSerde)")
        writer.write("import SmithySerialization")
        writer.write("")

        let sortedOperations = ctx.model.allShapesSorted
            .filter { $0.type == .operation }
            .compactMap { $0 as? OperationShape }

        let clientSymbol = try ctx.symbolProvider.swiftType(shape: ctx.service)

        writer.write("@_spi(SchemaBasedSerde)")
        try writer.openBlock("\(ctx.settings.scope) extension \(clientSymbol) {", "}") { writer in
            for operation in sortedOperations {
                writer.write("")
                let varName = "\(try ctx.symbolProvider.operationMethodName(operation: operation))Operation"
                let type = "SmithySerialization.Operation"
                let input = try ctx.symbolProvider.swiftType(shape: operation.input)
                let output = try ctx.symbolProvider.swiftType(shape: operation.output)
                try writer.openBlock("static var \(varName): \(type)<\(input), \(output)> {", "}") { writer in
                    try writer.openBlock(".init(", ")") { writer in
                        writer.write("schema: \(try ctx.symbolProvider.schemaVarName(shape: operation)),")
                        writer.write("serviceSchema: \(try ctx.symbolProvider.schemaVarName(shape: ctx.service)),")
                        writer.write("inputSchema: \(try ctx.symbolProvider.schemaVarName(shape: operation.input)),")
                        writer.write("outputSchema: \(try ctx.symbolProvider.schemaVarName(shape: operation.output)),")
                        let operationName = try ctx.symbolProvider.operationMethodName(operation: operation)
                        let registryName = "\(operationName)ErrorTypeRegistry"
                        writer.write("errorTypeRegistry: \(clientSymbol).\(registryName)")
                    }
                }
            }
        }
        return writer.contents
    }
}
