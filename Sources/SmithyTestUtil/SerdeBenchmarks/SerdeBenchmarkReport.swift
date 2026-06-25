//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct SerdeBenchmarkReport: Codable {
    public let metadata: SerdeBenchmarkMetadata
    public let serdeBenchmarks: [SerdeBenchmark]

    public enum CodingKeys: String, CodingKey {
        case metadata
        case serdeBenchmarks = "serde_benchmarks"
    }

    public static func update(at path: String, with serdeBenchmark: SerdeBenchmark) throws {
        let fileURL = URL(fileURLWithPath: path)
        let newSerdeBenchmarkReport: SerdeBenchmarkReport
        if FileManager.default.fileExists(atPath: path) {
            let data = try Data(contentsOf: fileURL)
            let serdeBenchmarkReport = try JSONDecoder().decode(Self.self, from: data)
            newSerdeBenchmarkReport = serdeBenchmarkReport.adding(serdeBenchmark: serdeBenchmark)
        } else {
            newSerdeBenchmarkReport = Self(serdeBenchmarks: [serdeBenchmark])
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(newSerdeBenchmarkReport)
        try data.write(to: fileURL)
    }

    public init(
        lang: String = "swift",
        software: [[String]] = [
            ["swift", "6.3.2"],
            ["smithy-swift", "0.206.0"],
        ],
        os: String = "Ubuntu 24.04 LTS (x86_64)",
        instance: String = "m7i.xlarge",
        precision: String = "-9",
        serdeBenchmarks: [SerdeBenchmark]
    ) {
        self.metadata = SerdeBenchmarkMetadata(
            lang: lang,
            software: software,
            os: os,
            instance: instance,
            precision: precision
        )
        self.serdeBenchmarks = serdeBenchmarks
    }

    public func adding(serdeBenchmark: SerdeBenchmark) -> Self {
        let newSerdeBenchmarks = self.serdeBenchmarks.filter { $0.id != serdeBenchmark.id } + [serdeBenchmark]
        return SerdeBenchmarkReport(
            lang: self.metadata.lang,
            software: self.metadata.software,
            os: self.metadata.os,
            instance: self.metadata.instance,
            precision: self.metadata.precision,
            serdeBenchmarks: newSerdeBenchmarks.sorted { $0.id < $1.id }
        )
    }
}
