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

    /// `min(b * r^i, MAX_BACKOFF)` — MAX_BACKOFF applied after jitter.
    public func computeNextBackoffDelay(attempt: Int) -> TimeInterval {
        random() * min(pow(r, Double(attempt)), options.maxBackoff)
    }

    /// Computes backoff with variable base multiplier `x`.
    /// Formula: `b * min(x * r^i, MAX_BACKOFF)` — MAX_BACKOFF is applied before jitter.
    public func computeNextBackoffDelay(attempt: Int, baseMultiplier: TimeInterval) -> TimeInterval {
        random() * min(baseMultiplier * pow(r, Double(attempt)), options.maxBackoff)
    }

    /// `b * min(x * r^i, MAX_BACKOFF)` — MAX_BACKOFF applied before jitter.
    public func computeNextBackoffDelay(attempt: Int, baseMultiplier: TimeInterval) -> TimeInterval {
        random() * min(baseMultiplier * pow(r, Double(attempt)), options.maxBackoff)
    }
}
