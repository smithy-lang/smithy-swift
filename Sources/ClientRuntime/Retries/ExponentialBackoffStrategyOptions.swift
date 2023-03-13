//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ExponentialBackoffStrategyOptions {
    let jitterType: ExponentialBackOffJitterType
    let backoffScaleValue: TimeInterval
}
