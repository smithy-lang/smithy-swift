//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct SerdeBenchmarker {

    public enum TestType {
        case request
        case response
    }

    public init() {}

    public func test(
        id: String,
        type: TestType,
        path: String,
        telemetryProvider: SerdeBenchmarkTelemetryProvider,
        operation: () async throws -> Void
    ) async throws {
        let warmups = 1000
        let minRuns = 1000
        let maxRuns = 10000
        let maxDuration: Foundation.TimeInterval = 30.0

        var n = 0
        var elapsedTime: Foundation.TimeInterval = 0.0
        var measurements: [Double] = []

        // Test for at least minRuns, no matter how long it takes
        // Once minRuns is met, test until either maxRuns or elapsedTime is reached
        let start = Foundation.Date()
        while (n <= warmups + minRuns) || ((n <= warmups + maxRuns) && (elapsedTime <= maxDuration)) {
            _ = try await operation()
            if n > warmups {
                let measurement = switch type {
                case .request:
                    telemetryProvider.requestHistogram.value
                case .response:
                    telemetryProvider.responseHistogram.value
                }
                measurements.append(measurement)
            }
            n += 1
            elapsedTime = Foundation.Date().timeIntervalSince(start)
        }

        let serdeBenchmark = SerdeBenchmark(id: id, measurements: measurements)
        try SerdeBenchmarkReport.update(at: path, with: serdeBenchmark)
    }
}
