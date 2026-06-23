//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import struct Smithy.ErrorTrait

struct TypeRegistryCodegen {

    func generate(ctx: GenerationContext) throws -> String {
        let writer = SwiftWriter()

        writer.write("@_spi(SchemaBasedSerde)")
        writer.write("import SmithySerialization")
        writer.write("")

        let serviceType = try ctx.symbolProvider.swiftType(shape: ctx.symbolProvider.service)
        try writer.openBlock("extension \(serviceType) {", "}") { writer in

            // Get all operations.  An ErrorTypeRegistry will be created for each operation.
            let allOperations = ctx.model.allShapesSorted.compactMap { $0 as? OperationShape }
            for operation in allOperations {
                writer.write("")
                let operationName = try ctx.symbolProvider.operationMethodName(operation: operation)
                let type = "SmithySerialization.TypeRegistry"
                writer.write("@_spi(SchemaBasedSerde)")
                try writer.openBlock(
                    "public static var \(operationName)ErrorTypeRegistry: \(type) {",
                    "}"
                ) { writer in
                    try writer.openBlock("\(type)(", ")") { writer in
                        // Get service errors sorted alphabetically, then operation errors sorted alphabetically
                        // This matches the behavior in current error matching where sorted service errors are tested for
                        // match first, followed by sorted operation errors.  See HTTPResponseBindingErrorGenerator.kt
                        let allServiceErrorsSorted = try ctx.service.errors.smithySorted()
                        let allOperationErrorsSorted = try operation.errors.smithySorted()
                        // Combine the errors into a single list, service first, then operations
                        let errors = allServiceErrorsSorted + allOperationErrorsSorted

                        try writer.openBlock("[", "]") { writer in
                            try errors.forEach { errorShape in
                                try writer.openBlock(".init(", "),") { writer in
                                    let schemaVarName = try ctx.symbolProvider.schemaVarName(shape: errorShape)
                                    writer.write("schema: \(schemaVarName),")
                                    let swiftType = try ctx.symbolProvider.swiftType(shape: errorShape)
                                    writer.write("swiftType: \(swiftType).self")
                                }
                            }
                        }
                    }
                }
            }
        }
        return writer.contents
    }
}
