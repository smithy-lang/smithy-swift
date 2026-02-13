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

        // Get the smithy-model-info.json file contents.
        let modelInfoData = try Data(contentsOf: URL(fileURLWithPath: inputPath.string))
        let smithyModelInfo = try JSONDecoder().decode(SmithyModelInfo.self, from: modelInfoData)

        // Get the fields from smithy-model-info.
        let service = smithyModelInfo.service
        let modelPathURL = currentWorkingDirectoryFileURL.appendingPathComponent(smithyModelInfo.path)
        let modelPath = Path(modelPathURL.path)
        let `internal` = smithyModelInfo.`internal` ?? false
        let operations = (smithyModelInfo.operations ?? []).joined(separator: ",")

        // Construct the Schemas.swift path.
        let schemasSwiftPath = outputDirectoryPath.appending("\(name)Schemas.swift")

        // Construct the Serialize.swift path.
        let serializeSwiftPath = outputDirectoryPath.appending("\(name)Serialize.swift")

        // Construct the Deserialize.swift path.
        let deserializeSwiftPath = outputDirectoryPath.appending("\(name)Deserialize.swift")

        // Construct the Deserialize.swift path.
        let typeRegistrySwiftPath = outputDirectoryPath.appending("\(name)TypeRegistry.swift")

        // Construct the Operations.swift path.
        let operationsSwiftPath = outputDirectoryPath.appending("\(name)Operations.swift")

        // Construct the build command that invokes SmithyCodegenCLI.
        return .buildCommand(
            displayName: "Generating Swift source files from model file \(smithyModelInfo.path)",
            executable: generatorToolPath,
            arguments: [
                service,
                modelPath,
                "--internal", "\(`internal`)",
                "--operations", operations,
                "--schemas-path", schemasSwiftPath,
                "--serialize-path", serializeSwiftPath,
                "--deserialize-path", deserializeSwiftPath,
                "--type-registry-path", typeRegistrySwiftPath,
                "--operations-path", operationsSwiftPath,
                "--schemas-path", schemasSwiftPath
            ],
            inputFiles: [inputPath, modelPath],
            outputFiles: [
                schemasSwiftPath,
                serializeSwiftPath,
                deserializeSwiftPath,
                typeRegistrySwiftPath,
                operationsSwiftPath,
            ]
        )
    }
}

/// Decodable structure for reading the contents of `smithy-model-info.json`
private struct SmithyModelInfo: Decodable {
    /// The shape ID of the service being generated.  Must exist in the model.
    let service: String

    /// The path to the model, from the root of the target's project.  Required.
    let path: String
    
    /// Set to `true` if the client should be rendered for internal use.
    let `internal`: Bool?

    /// A list of operations to be included in the client.  If omitted or empty, all operations are included.
    let operations: [String]?
}
