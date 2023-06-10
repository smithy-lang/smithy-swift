//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

struct ExponentialBackoffStrategyOptions {

    static let `default` = ExponentialBackoffStrategyOptions(jitterType: .default, backoffScaleValue: 0.025, maxBackoff: 20.0)

    let jitterType: ExponentialBackOffJitterType

    /// Scaling factor to add for the backoff. Default is 25ms
    let backoffScaleValue: TimeInterval

    let maxBackoff: TimeInterval

    init(jitterType: ExponentialBackOffJitterType, backoffScaleValue: TimeInterval, maxBackoff: TimeInterval) {
        self.jitterType = jitterType
        self.backoffScaleValue = backoffScaleValue
        self.maxBackoff = maxBackoff
    }
}
