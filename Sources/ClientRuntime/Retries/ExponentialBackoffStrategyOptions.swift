//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ExponentialBackoffStrategyOptions {

    static let `default` = ExponentialBackoffStrategyOptions(jitterType: .default, backoffScaleValue: 0.025)

    let jitterType: ExponentialBackOffJitterType

    /// Scaling factor to add for the backoff. Default is 25ms
    let backoffScaleValue: TimeInterval

    init(jitterType: ExponentialBackOffJitterType, backoffScaleValue: TimeInterval) {
        self.jitterType = jitterType
        self.backoffScaleValue = backoffScaleValue
    }
}
