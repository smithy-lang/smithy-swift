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
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID

/// The wrapper for Swift-native code generation.
public struct CodeGenerator {
    let swiftSettingsFileURL: URL
    let modelFileURL: URL
    let schemasFileURL: URL?
    let serializeFileURL: URL?
    let deserializeFileURL: URL?
    let typeRegistryFileURL: URL?
    let operationsFileURL: URL?

    /// Creates a code generator.
    /// - Parameters:
    ///   - service: The absolute shape ID of the service to be generated.  A service with this ID must exist in the model.
    ///   - modelFileURL: The file URL where the JSON AST model file can be accessed.
    ///   - schemasFileURL: The file URL to which the `Schemas.swift` source file should be written.
    public init(
        swiftSettingsFileURL: URL,
        modelFileURL: URL,
        schemasFileURL: URL?,
        serializeFileURL: URL?,
        deserializeFileURL: URL?,
        typeRegistryFileURL: URL?,
        operationsFileURL: URL?
    ) throws {
        self.swiftSettingsFileURL = swiftSettingsFileURL
        self.modelFileURL = modelFileURL
        self.schemasFileURL = schemasFileURL
        self.serializeFileURL = serializeFileURL
        self.deserializeFileURL = deserializeFileURL
        self.typeRegistryFileURL = typeRegistryFileURL
        self.operationsFileURL = operationsFileURL
    }

    /// Executes the code generator.
    ///
    /// The model is loaded and processed, then Swift source files are generated and written to the specified URL(s).
    public func run() throws {
        // Load the SwiftSettings from the JSON file
        let swiftSettingsData = try Data(contentsOf: swiftSettingsFileURL)
        let settings = try JSONDecoder().decode(SwiftSettings.self, from: swiftSettingsData)

        // Load the AST from the model file
        let modelData = try Data(contentsOf: modelFileURL)
        let astModel = try JSONDecoder().decode(ASTModel.self, from: modelData)

        // Create the model from the AST
        let model = try Model(astModel: astModel)

        // Create a generation context from the model
        let ctx = try GenerationContext(settings: settings, model: model)

        // If a schemas file URL was provided, generate it
        if let schemasFileURL {
            let schemasContents = try SchemasCodegen().generate(ctx: ctx)
            try Data(schemasContents.utf8).writeIfChanged(to: schemasFileURL)
        }

        // If a Serialize file URL was provided, generate it
        if let serializeFileURL {
            let serializeContents = try SerializeCodegen().generate(ctx: ctx)
            try Data(serializeContents.utf8).writeIfChanged(to: serializeFileURL)
        }

        // If a Deserialize file URL was provided, generate it
        if let deserializeFileURL {
            let deserializeContents = try DeserializeCodegen().generate(ctx: ctx)
            try Data(deserializeContents.utf8).writeIfChanged(to: deserializeFileURL)
        }

        // If a TypeRegistry file URL was provided, generate it
        if let typeRegistryFileURL {
            let typeRegistryContents = try TypeRegistryCodegen().generate(ctx: ctx)
            try Data(typeRegistryContents.utf8).writeIfChanged(to: typeRegistryFileURL)
        }

        // If an Operations file URL was provided, generate it
        if let operationsFileURL {
            let operationsContents = try OperationsCodegen().generate(ctx: ctx)
            try Data(operationsContents.utf8).writeIfChanged(to: operationsFileURL)
        }
    }
}

private extension Data {

    // Read the existing code-generated source file, and rewrite the file only if
    // the new contents are different from the existing contents.
    //
    // This mitigates the Xcode-specific bug described in https://github.com/swiftlang/swift-build/issues/305
    // which causes generated code to regenerate and recompile to happen on every incremental build,
    // even when there was no change to build inputs.
    //
    // Using a hash (i.e. SHA-256) to reduce memory usage during file contents comparison was considered
    // but rejected because it would require adding swift-crypto as a dependency to the code generator.
    //
    // On Linux, where this bug does not exist because the Xcode build system is not used,
    // the check is skipped and the file contents are always rewritten.
    func writeIfChanged(to url: URL) throws {
        #if !os(Linux)
        if FileManager.default.fileExists(atPath: url.path) {
            let existingData = try Data(contentsOf: url)
            guard existingData != self else { return }
        }
        #endif
        try write(to: url)
    }
}
