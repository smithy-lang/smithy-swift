//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import class Foundation.JSONDecoder
import struct Foundation.URL
import struct Smithy.ShapeID

public struct CodeGenerator {
    let service: String
    let modelFileURL: URL
    let schemasFileURL: URL?

    public init(
        service: String,
        modelFileURL: URL,
        schemasFileURL: URL?
    ) throws {
        self.service = service
        self.modelFileURL = modelFileURL
        self.schemasFileURL = schemasFileURL
    }

    public func run() throws {
        // Load the AST from the model file
        let modelData = try Data(contentsOf: modelFileURL)
        let astModel = try JSONDecoder().decode(ASTModel.self, from: modelData)

        // Create the service's ShapeID
        let serviceID = try ShapeID(service)

        // Create the model from the AST
        let model = try Model(astModel: astModel)

        // Create a generation context from the model
        let ctx = try GenerationContext(serviceID: serviceID, model: model)

        // If a schemas file URL was provided, generate it
        if let schemasFileURL {
            let schemasContents = try SchemasCodegen().generate(ctx: ctx)
            try Data(schemasContents.utf8).write(to: schemasFileURL)
        }
    }
}
