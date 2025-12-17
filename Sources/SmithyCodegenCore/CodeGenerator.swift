//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import class Foundation.FileManager
import class Foundation.JSONDecoder
import struct Foundation.URL

public struct CodeGenerator {
    let modelFileURL: URL
    let schemasFileURL: URL?

    public init(
        modelFileURL: URL,
        schemasFileURL: URL?
    ) {
        self.modelFileURL = modelFileURL
        self.schemasFileURL = schemasFileURL
    }

    public func run() throws {
        // Load the AST from the model file
        let modelData = try Data(contentsOf: modelFileURL)
        let astModel = try JSONDecoder().decode(ASTModel.self, from: modelData)

        // Create the model from the AST
        let model = try Model(astModel: astModel)

        // Create a generation context from the model
        let _ = try GenerationContext(model: model)

        // Generation context will be used here in the future
        // to generate needed files.

        // This code simply writes an empty schemas file, since it is expected to exist after the
        // code generator plugin runs.
        //
        // Actual code generation will be implemented here later.
        if let schemasFileURL {
            FileManager.default.createFile(atPath: schemasFileURL.path, contents: Data())
        }
    }
}
