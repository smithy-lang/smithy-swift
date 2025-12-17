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
    let serializableStructsFileURL: URL?

    public init(
        modelFileURL: URL,
        schemasFileURL: URL?,
        serializableStructsFileURL: URL?
    ) {
        self.modelFileURL = modelFileURL
        self.schemasFileURL = schemasFileURL
        self.serializableStructsFileURL = serializableStructsFileURL
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

        // If a serializable structs file URL was provided, generate it
        if let serializableStructsFileURL {
            let serializableStructsContents = try SerializableStructsCodegen().generate(ctx: ctx)
            try Data(serializableStructsContents.utf8).write(to: serializableStructsFileURL)
        }
    }
}
