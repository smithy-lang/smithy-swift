//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.URL

public struct CodeGenerator {
    let modelFileURL: URL
    let schemasFileURL: URL?

    public init(modelFileURL: URL, schemasFileURL: URL?) {
        self.modelFileURL = modelFileURL
        self.schemasFileURL = schemasFileURL
    }

    public func run() throws {
        // Load the model from the model file
        let model = try Model(modelFileURL: modelFileURL)

        // If a schema file URL was provided, generate it
        if let schemasFileURL {
            let schemaContents = try SmithySchemaCodegen().generate(model: model)
            try Data(schemaContents.utf8).write(to: schemasFileURL)
        }
    }
}
