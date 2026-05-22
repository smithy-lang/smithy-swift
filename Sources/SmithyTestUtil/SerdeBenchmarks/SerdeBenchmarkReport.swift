//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct SerdeBenchmarkReport: Codable {
    public let lang: String
    public let software: [[String: String]]
    public let os: String
    public let instance: String
    public let precision: String
    public let serdeBenchmarks: [SerdeBenchmark]

    public enum CodingKeys: String, CodingKey {
        case lang
        case software
        case os
        case instance
        case precision
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
        lang: String = "Swift",
        software: [[String: String]] = [
            ["swift": "6.3.2"],
            ["smithy-swift": "0.206.0"],
        ],
        os: String = "Ubuntu 24.04 LTS (x86_64)",
        instance: String = "m7i.xlarge",
        precision: String = "-9",
        serdeBenchmarks: [SerdeBenchmark]
    ) {
        self.lang = lang
        self.software = software
        self.os = os
        self.instance = instance
        self.precision = precision
        self.serdeBenchmarks = serdeBenchmarks
    }

    public func adding(serdeBenchmark: SerdeBenchmark) -> Self {
        let newSerdeBenchmarks = self.serdeBenchmarks.filter { $0.id != serdeBenchmark.id } + [serdeBenchmark]
        return SerdeBenchmarkReport(
            lang: self.lang,
            software: self.software,
            os: self.os,
            instance: self.instance,
            precision: self.precision,
            serdeBenchmarks: newSerdeBenchmarks.sorted { $0.id < $1.id }
        )
    }
}
