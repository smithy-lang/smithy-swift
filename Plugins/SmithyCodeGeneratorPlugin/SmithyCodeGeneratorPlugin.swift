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
import PackagePlugin

@main
struct SmithyCodeGeneratorPlugin: BuildToolPlugin {

    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        // This plugin only runs for package targets that can have source files.
        guard let sourceFiles = target.sourceModule?.sourceFiles else { return [] }

        // Retrieve the `SmithyCodegenCLI` tool from the plugin's tools.
        let smithyCodegenCLITool = try context.tool(named: "SmithyCodegenCLI")

        // Construct a build command for each source file with a particular suffix.
        return try sourceFiles.map(\.url).compactMap {
            try createBuildCommand(
                name: target.name,
                for: $0,
                in: context.pluginWorkDirectoryURL,
                with: smithyCodegenCLITool.url
            )
        }
    }

    private func createBuildCommand(
        name: String,
        for inputURL: URL,
        in outputDirectoryURL: URL,
        with generatorToolURL: URL
    ) throws -> Command? {
        // Skip any file that isn't the swift-settings.json for this service.
        guard inputURL.lastPathComponent == "swift-settings.json" else { return nil }

        let currentWorkingDirectoryFileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        // Get the swift-settings.json file path.
        let swiftSettingsPath = inputURL.path

        // Get the model path URL field from swift-settings.json.
        let swiftSettingsData = try Data(contentsOf: inputURL)
        let swiftSettingsModelInfo = try JSONDecoder().decode(SwiftSettingsModelInfo.self, from: swiftSettingsData)
        let modelPathURL = if let modelPath = swiftSettingsModelInfo.modelPath {
            currentWorkingDirectoryFileURL.appendingPathComponent(modelPath)
        } else {
            inputURL.deletingLastPathComponent().appendingPathComponent("model.json")
        }

        // Construct the Schemas.swift path.
        let schemasSwiftURL = outputDirectoryURL.appendingPathComponent("\(name)Schemas.swift")

        // Construct the Serialize.swift path.
        let serializeSwiftURL = outputDirectoryURL.appendingPathComponent("\(name)Serialize.swift")

        // Construct the Deserialize.swift path.
        let deserializeSwiftURL = outputDirectoryURL.appendingPathComponent("\(name)Deserialize.swift")

        // Construct the TypeRegistry.swift path.
        let typeRegistrySwiftURL = outputDirectoryURL.appendingPathComponent("\(name)TypeRegistry.swift")

        // Construct the Operations.swift path.
        let operationsSwiftURL = outputDirectoryURL.appendingPathComponent("\(name)Operations.swift")

        let arguments: [String] = [
            "--swift-settings-path", swiftSettingsPath,
            "--model-path", modelPathURL.path,
            "--schemas-path", schemasSwiftURL.path,
            "--serialize-path", serializeSwiftURL.path,
            "--deserialize-path", deserializeSwiftURL.path,
            "--type-registry-path", typeRegistrySwiftURL.path,
            "--operations-path", operationsSwiftURL.path,
        ]

        // Construct the build command that invokes SmithyCodegenCLI.
        return .buildCommand(
            displayName: "Generating Swift source files from model file \(modelPathURL.path)",
            executable: generatorToolURL,
            arguments: arguments,
            inputFiles: [inputURL, modelPathURL],
            outputFiles: [
                schemasSwiftURL,
                serializeSwiftURL,
                deserializeSwiftURL,
                typeRegistrySwiftURL,
                operationsSwiftURL,
            ]
        )
    }
}

/// Decodable structure for reading the model path from `swift-settings.json`.
private struct SwiftSettingsModelInfo: Decodable {
    /// The path to the model, from the root of the target's project.
    let modelPath: String?
}
