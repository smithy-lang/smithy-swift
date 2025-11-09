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

    private func createBuildCommand(
        for inputPath: Path,
        in outputDirectoryPath: Path,
        with generatorToolPath: Path
    ) throws -> Command? {
        let currentWorkingDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        // Skip any file that isn't the smithy-model-info.json for this service.
        guard inputPath.lastComponent == "smithy-model-info.json" else { return nil }

        // Get the smithy model path.
        let modelInfoData = try Data(contentsOf: URL(filePath: inputPath.string))
        let smithyModelInfo = try JSONDecoder().decode(SmithyModelInfo.self, from: modelInfoData)
        let modelPathURL = currentWorkingDirectoryURL.appendingPathComponent(smithyModelInfo.path)
        let modelPath = Path(modelPathURL.path)

        // Return a command that will run during the build to generate the output file.
        let inputName = inputPath.lastComponent
        let schemasSwiftPath = outputDirectoryPath.appending("Schemas.swift")
        return .buildCommand(
            displayName: "Generating Schemas.swift from \(inputName)",
            executable: generatorToolPath,
            arguments: [modelPath, schemasSwiftPath],
            inputFiles: [inputPath, modelPath],
            outputFiles: [schemasSwiftPath]
        )
    }
}

struct SmithySchemaGeneratorPluginError: Error {
    let localizedDescription: String

    init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}

struct SmithyModelInfo: Codable {
    let path: String
}
