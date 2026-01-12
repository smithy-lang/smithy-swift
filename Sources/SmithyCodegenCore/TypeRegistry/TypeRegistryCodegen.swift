//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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
                    .filter { $0.hasTrait(.init("smithy.api", "error")) }
                if allErrorShapesSorted.isEmpty {
                    writer.write("[:]")
                } else {
                    try writer.openBlock("[", "]") { writer in
                        try allErrorShapesSorted.forEach { errorShape in
                            let idLiteral = ".init(\(errorShape.id.namespace.literal), \(errorShape.id.name.literal))"
                            let swiftType = try ctx.symbolProvider.swiftType(shape: errorShape)
                            writer.write("\(idLiteral): \(swiftType).self,")
                        }
                    }
                }
            }
        }
        return writer.finalize()
    }
}
