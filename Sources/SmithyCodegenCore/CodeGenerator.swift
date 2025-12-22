//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import class Foundation.JSONDecoder
import struct Foundation.URL

public struct CodeGenerator {
    let modelFileURL: URL
    let schemasFileURL: URL?
    let serializeFileURL: URL?
    let deserializeFileURL: URL?

    public init(
        modelFileURL: URL,
        schemasFileURL: URL?,
        serializeFileURL: URL?,
        deserializeFileURL: URL?
    ) {
        self.modelFileURL = modelFileURL
        self.schemasFileURL = schemasFileURL
        self.serializeFileURL = serializeFileURL
        self.deserializeFileURL = deserializeFileURL
    }

    public func run() throws {
        // Load the AST from the model file
        let modelData = try Data(contentsOf: modelFileURL)
        let astModel = try JSONDecoder().decode(ASTModel.self, from: modelData)

        // Create the model from the AST
        let model = try Model(astModel: astModel)

        // Create a generation context from the model
        let ctx = try GenerationContext(model: model)

        // If a schemas file URL was provided, generate it
        if let schemasFileURL {
            let schemasContents = try SmithySchemaCodegen().generate(ctx: ctx)
            try Data(schemasContents.utf8).write(to: schemasFileURL)
        }

        // If a Serialize file URL was provided, generate it
        if let serializeFileURL {
            let serializeContents = try SerializeCodegen().generate(ctx: ctx)
            try Data(serializeContents.utf8).write(to: serializeFileURL)
        }

        // If a Deserialize file URL was provided, generate it
        if let deserializeFileURL {
            let deserializeContents = try DeserializeCodegen().generate(ctx: ctx)
            try Data(deserializeContents.utf8).write(to: deserializeFileURL)
        }
    }
}
