//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ErrorTrait

struct TypeRegistryCodegen {

    func generate(ctx: GenerationContext) throws -> String {
        let writer = SwiftWriter()

        writer.write("import SmithySerialization")
        writer.write("")

        let serviceType = try ctx.symbolProvider.swiftType(shape: ctx.symbolProvider.service)
        try writer.openBlock("extension \(serviceType) {", "}") { writer in
            writer.write("")
            try writer.openBlock(
                "public static let errorTypeRegistry = SmithySerialization.TypeRegistry(",
                ")"
            ) { writer in
                let allErrorShapesSorted = ctx.model.allShapesSorted
                    .filter { $0.hasTrait(ErrorTrait.self) }
                try writer.openBlock("[", "]") { writer in
                    try allErrorShapesSorted.forEach { errorShape in
                        try writer.openBlock(".init(", "),") { writer in
                            let schemaVarName = try errorShape.schemaVarName
                            writer.write("schema: \(schemaVarName),")
                            let swiftType = try ctx.symbolProvider.swiftType(shape: errorShape)
                            writer.write("swiftType: \(swiftType).self")
                        }
                    }
                }
            }
        }
        return writer.finalize()
    }
}
