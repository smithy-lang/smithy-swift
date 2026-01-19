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
    let serializeFileURL: URL?
    let deserializeFileURL: URL?
    let typeRegistryFileURL: URL?
    let operationsFileURL: URL?

    public init(
        service: String,
        modelFileURL: URL,
        schemasFileURL: URL?,
        serializeFileURL: URL?,
        deserializeFileURL: URL?,
        typeRegistryFileURL: URL?,
        operationsFileURL: URL?
    ) throws {
        self.service = service
        self.modelFileURL = modelFileURL
        self.schemasFileURL = schemasFileURL
        self.serializeFileURL = serializeFileURL
        self.deserializeFileURL = deserializeFileURL
        self.typeRegistryFileURL = typeRegistryFileURL
        self.operationsFileURL = operationsFileURL
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

        // If a TypeRegistry file URL was provided, generate it
        if let typeRegistryFileURL {
            let typeRegistryContents = try TypeRegistryCodegen().generate(ctx: ctx)
            try Data(typeRegistryContents.utf8).write(to: typeRegistryFileURL)
        }

        // If an Operations file URL was provided, generate it
        if let operationsFileURL {
            let operationsContents = try OperationsCodegen().generate(ctx: ctx)
            try Data(operationsContents.utf8).write(to: operationsFileURL)
        }
    }
}
