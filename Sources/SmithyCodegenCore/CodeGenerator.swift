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

        // In the future, AST will be used to create a Model.
        // Model will be used to generate code.

        // This code simply writes an empty schemas file, since it is expected to exist after the
        // code generator plugin runs.
        //
        // Actual code generation will be implemented here later.
        if let schemasFileURL {
            FileManager.default.createFile(atPath: schemasFileURL.path, contents: Data())
        }
    }
}
