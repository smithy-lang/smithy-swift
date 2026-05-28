//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

public protocol RetryBackoffStrategy: Sendable {
    /// Returns a Duration that a caller performing retries should use for delaying between retries.
    ///
    /// A theoretical edge case here to watch out for..... integers overflow. Eventually this code would turn the delay ticks value past the
    /// maximum value for a fixed-width integer. In the case of an overflow, return the maximum valid representable value.
    func computeNextBackoffDelay(attempt: Int) -> TimeInterval

    /// Computes backoff with a variable base multiplier `x`.
    /// - Parameters:
    ///   - attempt: The zero-based retry attempt number.
    ///   - baseMultiplier: The `x` multiplier in `t_i = x * r^i`, in seconds.
    func computeNextBackoffDelay(attempt: Int, baseMultiplier: TimeInterval) -> TimeInterval
}

extension RetryBackoffStrategy {
    /// Compatibility shim for conformers that pre-date the `baseMultiplier` overload.
    /// The default implementation **drops `baseMultiplier`** and delegates to the
    /// single-argument variant.  Custom strategies that want gate-on backoff
    /// (per-error multipliers, max-before-jitter) MUST override this method.
    public func computeNextBackoffDelay(attempt: Int, baseMultiplier: TimeInterval) -> TimeInterval {
        computeNextBackoffDelay(attempt: attempt)
    }
}
