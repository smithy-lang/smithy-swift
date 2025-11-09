//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import PackagePlugin

@main
struct SmithyCodeGeneratorPlugin: BuildToolPlugin {

    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        // This plugin only runs for package targets that can have source files.
        guard let sourceFiles = target.sourceModule?.sourceFiles else { return [] }

        // Retrieve the `SmithySchemaCodegenTool` from the plugin's tools.
        let generatorTool = try context.tool(named: "SmithyCodegenCLI")

        // Construct a build command for each source file with a particular suffix.
        return try sourceFiles.map(\.path).compactMap {
            try createBuildCommand(for: $0, in: context.pluginWorkDirectory, with: generatorTool.path)
        }
    }

    private func createBuildCommand(for inputPath: Path, in outputDirectoryPath: Path, with generatorToolPath: Path) throws -> Command? {
        // Skip any file that isn't the model.json for this service.
        guard inputPath.lastComponent == "smithy-model-file-info.txt" else { return nil }

        // Get the smithy model path.
        let locationData = try Data(contentsOf: URL(filePath: inputPath.string))
        guard let location = String(data: locationData, encoding: .utf8) else {
            throw SmithySchemaGeneratorPluginError("smithy-model-file-info.txt did not contain valid UTF-8")
        }
        let modelPathURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(location.trimmingCharacters(in: .whitespacesAndNewlines))
        let modelPath = Path(modelPathURL.path)

        // Return a command that will run during the build to generate the output file.
        let inputName = inputPath.lastComponent
        let outputPath = outputDirectoryPath.appending("Schemas.swift")
        return .buildCommand(
            displayName: "Generating Schemas.swift from \(inputName)",
            executable: generatorToolPath,
            arguments: [modelPath, outputPath],
            inputFiles: [inputPath, modelPath],
            outputFiles: [outputPath]
        )
    }
}

struct SmithySchemaGeneratorPluginError: Error {
    let localizedDescription: String

    init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}
