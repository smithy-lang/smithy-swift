//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct SerdeBenchmark: Codable {
    public let id: String
    public let n: Int
    public let mean: Int
    public let p50: Int
    public let p90: Int
    public let p95: Int
    public let p99: Int
    public let std_dev: Int

    public init(id: String, n: Int, mean: Int, p50: Int, p90: Int, p95: Int, p99: Int, std_dev: Int) {
        self.id = id
        self.n = n
        self.mean = mean
        self.p50 = p50
        self.p90 = p90
        self.p95 = p95
        self.p99 = p99
        self.std_dev = std_dev
    }

    public init(id: String, measurements: [Double]) {
        let runCount = 10000

        // Calcluate mean
        var sum = 0.0
        for num in measurements {
            sum += num
        }
        let mean = sum / Double(runCount)

        // Calculate standard deviation
        var diffSquaredSum = 0.0
        for num in measurements {
            diffSquaredSum += (num - mean) * (num - mean)
        }
        let sd = sqrt(diffSquaredSum / Double(runCount - 1))
        let percentiles = Self.calculatePercentiles(measurements)
        self.id = id
        self.n = runCount
        self.mean = Int(mean * nsecPerSec)
        self.p50 = percentiles.p50
        self.p90 = percentiles.p90
        self.p95 = percentiles.p95
        self.p99 = percentiles.p99
        self.std_dev = Int(sd * nsecPerSec)
    }

    private static func calculatePercentiles(
        _ measurements: [Double]
    ) -> (p50: Int, p90: Int, p95: Int, p99: Int) {
        let sorted = measurements.sorted()
        let count = sorted.count

        func percentile(_ p: Double) -> Int {
            let index = p / 100.0 * Double(count - 1)
            let lower = Int(floor(index))
            let upper = Int(ceil(index))
            if lower == upper {
                return Int(sorted[lower] * nsecPerSec)
            }
            let fraction = index - Double(lower)
            return Int((sorted[lower] * (1 - fraction) + sorted[upper] * fraction) * nsecPerSec)
        }

        return (
            p50: percentile(50),
            p90: percentile(90),
            p95: percentile(95),
            p99: percentile(99)
        )
    }
}

private let nsecPerSec = 1_000_000_000.0
