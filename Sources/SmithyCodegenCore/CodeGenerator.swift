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
    let structConsumersFileURL: URL?

    public init(
        modelFileURL: URL,
        schemasFileURL: URL?,
        structConsumersFileURL: URL?
    ) {
        self.modelFileURL = modelFileURL
        self.schemasFileURL = schemasFileURL
        self.structConsumersFileURL = structConsumersFileURL
    }

    public func run() throws {
        // Load the AST from the model file
        let modelData = try Data(contentsOf: modelFileURL)
        let astModel = try JSONDecoder().decode(ASTModel.self, from: modelData)

        // Create the model from the AST
        let model = try Model(astModel: astModel)

        // If a schema file URL was provided, generate it
        if let schemasFileURL {
            let schemaContents = try SmithySchemaCodegen().generate(model: model)
            try Data(schemaContents.utf8).write(to: schemasFileURL)
        }

        // If a struct consumers file URL was provided, generate it
        if let structConsumersFileURL {
            let structConsumersContents = try StructConsumersCodegen().generate(model: model)
            try Data(structConsumersContents.utf8).write(to: structConsumersFileURL)
        }
    }
}
