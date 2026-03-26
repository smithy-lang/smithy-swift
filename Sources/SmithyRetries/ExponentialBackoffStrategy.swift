//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import func Foundation.pow
import struct Foundation.TimeInterval
import protocol SmithyRetriesAPI.RetryBackoffStrategy

public struct ExponentialBackoffStrategy: RetryBackoffStrategy {
    let options: ExponentialBackoffStrategyOptions

    var random: @Sendable () -> Double = { Double.random(in: 0.0...1.0) }

    // values set by Retry Behavior 2.0 SEP
    let r = 2.0

    public init() {
        self.init(options: ExponentialBackoffStrategyOptions())
    }

    init(options: ExponentialBackoffStrategyOptions) {
        self.options = options
    }

    public func computeNextBackoffDelay(attempt: Int) -> TimeInterval {
        min(random() * pow(r, Double(attempt)), options.maxBackoff)
    }

    /// Retries SEP 2.1: Computes backoff with variable base multiplier `x`.
    /// Formula: `min(random() * x * r^i, MAX_BACKOFF)` where jitter is applied before MAX_BACKOFF.
    public func computeNextBackoffDelay(attempt: Int, baseMultiplier: TimeInterval) -> TimeInterval {
        min(random() * baseMultiplier * pow(r, Double(attempt)), options.maxBackoff)
    }
}
