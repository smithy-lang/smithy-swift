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
        return try sourceFiles.map(\.path).compactMap {
            try createBuildCommand(for: $0, in: context.pluginWorkDirectory, with: smithyCodegenCLITool.path)
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
        let modelInfoData = try Data(contentsOf: URL(fileURLWithPath: inputPath.string))
        let smithyModelInfo = try JSONDecoder().decode(SmithyModelInfo.self, from: modelInfoData)
        let modelPathURL = currentWorkingDirectoryURL.appendingPathComponent(smithyModelInfo.path)
        let modelPath = Path(modelPathURL.path)

        // Return a command that will run during the build to generate the output file.
        let modelCountSwiftPath = outputDirectoryPath.appending("ModelCount.swift")
        return .buildCommand(
            displayName: "Generating Swift source files from \(smithyModelInfo.path)",
            executable: generatorToolPath,
            arguments: [modelPath, modelCountSwiftPath],
            inputFiles: [inputPath, modelPath],
            outputFiles: [modelCountSwiftPath]
        )
    }
}

/// Codable structure for reading the contents of `smithy-model-info.json`
private struct SmithyModelInfo: Decodable {
    /// The path to the model, from the root of the target's project.  Required.
    let path: String
}

struct Err: Error {
    var localizedDescription: String { "boom" }
}
