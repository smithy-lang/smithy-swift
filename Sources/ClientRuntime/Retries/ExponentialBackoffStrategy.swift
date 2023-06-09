//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import func Foundation.pow
import struct Foundation.TimeInterval

struct ExponentialBackoffStrategy: RetryBackoffStrategy {
    static let `default` = ExponentialBackoffStrategy(options: ExponentialBackoffStrategyOptions.default)

    let options: ExponentialBackoffStrategyOptions

    var random: () -> Double = { Double.random(in: 0.0...1.0) }

    // values set by Retry Behavior 2.0 SEP
    let r = 2.0
    let maxBackoff: TimeInterval = 20.0

    init(options: ExponentialBackoffStrategyOptions) {
        self.options = options
    }

    func computeNextBackoffDelay(attempt: Int) -> TimeInterval {
        min(random() * pow(r, Double(attempt)), maxBackoff)
    }
}
