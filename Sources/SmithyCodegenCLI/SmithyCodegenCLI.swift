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

        // Use resolved file URLs to run code generator
        try CodeGenerator(
            service: service,
            modelFileURL: modelFileURL,
            schemasFileURL: schemasFileURL
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
