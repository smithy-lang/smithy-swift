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

    @Argument(help: "The shape ID of the service to be code-generated.  Must exist in the model file.")
    var service: String

    @Argument(help: "The full or relative path to read the JSON AST model input file.")
    var modelPath: String

    @Option(help: "The full or relative path to write the Schemas output file.")
    var schemasPath: String?

    @Option(help: "The full or relative path to write the Serialize output file.")
    var serializePath: String?

    @Option(help: "The full or relative path to write the Deserialize output file.")
    var deserializePath: String?

    @Option(help: "The full or relative path to write the TypeRegistry output file.")
    var typeRegistryPath: String?

    @Option(help: "The full or relative path to write the Operations output file.")
    var operationsPath: String?

    func run() async throws {

        let start = Date()

        let currentWorkingDirectoryFileURL = currentWorkingDirectoryFileURL()

        // Create the model file URL
        let modelFileURL = URL(fileURLWithPath: modelPath, relativeTo: currentWorkingDirectoryFileURL)
        guard FileManager.default.fileExists(atPath: modelFileURL.path) else {
            throw SmithyCodegenCLIError(localizedDescription: "no file at model path \(modelFileURL.path)")
        }

        // If --schemas-path was supplied, create the schema file URL
        let schemasFileURL = resolve(path: schemasPath)

        // If --serialize-path was supplied, create the Serialize file URL
        let serializeFileURL = resolve(path: serializePath)

        // If --deserialize-path was supplied, create the Deserialize file URL
        let deserializeFileURL = resolve(path: deserializePath)

        // If --type-registry-path was supplied, create the TypeRegistry file URL
        let typeRegistryFileURL = resolve(path: typeRegistryPath)

        // If --operations-path was supplied, create the Operations file URL
        let operationsFileURL = resolve(path: operationsPath)

        // Use resolved file URLs to run code generator
        try CodeGenerator(
            service: service,
            modelFileURL: modelFileURL,
            schemasFileURL: schemasFileURL,
            serializeFileURL: serializeFileURL,
            deserializeFileURL: deserializeFileURL,
            typeRegistryFileURL: typeRegistryFileURL,
            operationsFileURL: operationsFileURL
        ).run()

        let duration = Date().timeIntervalSince(start)
        let secondsDuration = String(
            format: "%0.2f",
            locale: Locale(identifier: "en_US_POSIX"),
            arguments: [duration]
        )
        print("Completed generating model \(modelFileURL.lastPathComponent) in \(secondsDuration) sec")
    }

    private func currentWorkingDirectoryFileURL() -> URL {
        // Get the current working directory as a file URL
        var currentWorkingDirectoryPath = FileManager.default.currentDirectoryPath
        if !currentWorkingDirectoryPath.hasSuffix("/") {
            currentWorkingDirectoryPath.append("/")
        }
        return URL(fileURLWithPath: currentWorkingDirectoryPath)
    }

    private func resolve(path: String?) -> URL? {
        guard let path else { return nil }
        return URL(fileURLWithPath: path, relativeTo: currentWorkingDirectoryFileURL())
    }
}

struct SmithyCodegenCLIError: Error {
    let localizedDescription: String
}
