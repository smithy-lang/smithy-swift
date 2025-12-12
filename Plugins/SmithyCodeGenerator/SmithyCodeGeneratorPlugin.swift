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
            try createBuildCommand(
                name: target.name,
                for: $0,
                in: context.pluginWorkDirectory,
                with: smithyCodegenCLITool.path
            )
        }
    }

    private func createBuildCommand(
        name: String,
        for inputPath: Path,
        in outputDirectoryPath: Path,
        with generatorToolPath: Path
    ) throws -> Command? {
        // Skip any file that isn't the smithy-model-info.json for this service.
        guard inputPath.lastComponent == "smithy-model-info.json" else { return nil }

        let currentWorkingDirectoryFileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        // Get the smithy model path.
        let modelInfoData = try Data(contentsOf: URL(fileURLWithPath: inputPath.string))
        let smithyModelInfo = try JSONDecoder().decode(SmithyModelInfo.self, from: modelInfoData)
        let modelPathURL = currentWorkingDirectoryFileURL.appendingPathComponent(smithyModelInfo.path)
        let modelPath = Path(modelPathURL.path)

        // Construct the schemas.swift path.
        let schemasSwiftPath = outputDirectoryPath.appending("\(name)Schemas.swift")

        // Construct the structconsumers.swift path.
        let structConsumersSwiftPath = outputDirectoryPath.appending("\(name)StructConsumers.swift")

        // Construct the build command that invokes SmithyCodegenCLI.
        return .buildCommand(
            displayName: "Generating Swift source files from model file \(smithyModelInfo.path)",
            executable: generatorToolPath,
            arguments: [
                "--schemas-path", schemasSwiftPath,
                "--struct-consumers-path", structConsumersSwiftPath,
                modelPath
            ],
            inputFiles: [inputPath, modelPath],
            outputFiles: [schemasSwiftPath, structConsumersSwiftPath]
        )
    }
}

/// Codable structure for reading the contents of `smithy-model-info.json`
private struct SmithyModelInfo: Decodable {
    /// The path to the model, from the root of the target's project.  Required.
    let path: String
}
