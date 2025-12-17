//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ArgumentParser
import Foundation
import struct SmithyCodegenCore.CodeGenerator

@main
struct SmithyCodegenCLI: AsyncParsableCommand {

    @Argument(help: "The full or relative path to the JSON model file.")
    var modelPath: String

    @Option(help: "The full or relative path to write the schemas output file.")
    var schemasPath: String?

    @Option(help: "The full or relative path to write the SerializableStructs output file.")
    var serializableStructsPath: String?

    func run() async throws {
        let currentWorkingDirectoryFileURL = currentWorkingDirectoryFileURL()
        print("Current working directory: \(currentWorkingDirectoryFileURL.path)")

        // Create the model file URL
        let modelFileURL = URL(fileURLWithPath: modelPath, relativeTo: currentWorkingDirectoryFileURL)
        guard FileManager.default.fileExists(atPath: modelFileURL.path) else {
            throw SmithyCodegenCLIError(localizedDescription: "no file at model path \(modelFileURL.path)")
        }
        print("Model file path: \(modelFileURL.path)")

        // If --schemas-path was supplied, create the schema file URL
        let schemasFileURL = resolve(paramName: "--schemas-path", path: schemasPath)

        // If --serializable-structs-path was supplied, create the serializable structs file URL
        let serializableStructsFileURL = resolve(paramName: "--serializable-structs-path", path: serializableStructsPath)

        // Use resolved file URLs to run code generator
        try CodeGenerator(
            modelFileURL: modelFileURL,
            schemasFileURL: schemasFileURL,
            serializableStructsFileURL: serializableStructsFileURL
        ).run()
    }

    private func currentWorkingDirectoryFileURL() -> URL {
        // Get the current working directory as a file URL
        var currentWorkingDirectoryPath = FileManager.default.currentDirectoryPath
        if !currentWorkingDirectoryPath.hasSuffix("/") {
            currentWorkingDirectoryPath.append("/")
        }
        return URL(fileURLWithPath: currentWorkingDirectoryPath)
    }

    private func resolve(paramName: String, path: String?) -> URL? {
        if let path {
            let fileURL = URL(fileURLWithPath: path, relativeTo: currentWorkingDirectoryFileURL())
            print("Resolved \(paramName): \(fileURL.path)")
            return fileURL
        } else {
            print("\(paramName) not provided, skipping generation")
            return nil
        }
    }
}

struct SmithyCodegenCLIError: Error {
    let localizedDescription: String
}
