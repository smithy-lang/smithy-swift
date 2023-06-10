//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

struct ExponentialBackoffStrategyOptions {

    let jitterType: ExponentialBackOffJitterType

    /// Scaling factor to add for the backoff. Default is 25ms
    let backoffScaleValue: TimeInterval

    /// The maximum amount of time to wait between retries.  Defaults to 20 seconds.
    let maxBackoff: TimeInterval

    /// Creates parameters for configuring exponential retry backoff delays.
    /// - Parameters:
    ///   - jitterType: The jitter to be used when determining backoff delays.  Defaults to `.default`, currently unused.
    ///   - backoffScaleValue: The backoff scale value.  Defaults to 0.025 seconds, currently unused.
    ///   - maxBackoff: The maximum amount of time to wait between retries.  Defaults to 20 seconds.
    init(
        jitterType: ExponentialBackOffJitterType = .default,
        backoffScaleValue: TimeInterval = 0.025,
        maxBackoff: TimeInterval = 20.0
    ) {
        self.jitterType = jitterType
        self.backoffScaleValue = backoffScaleValue
        self.maxBackoff = maxBackoff
    }
}
