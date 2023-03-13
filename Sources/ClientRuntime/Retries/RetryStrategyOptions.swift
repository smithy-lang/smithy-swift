//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval
import AwsCommonRuntimeKit

public struct RetryStrategyOptions {
    public let backoffStrategy: RetryBackoffStrategy
    public let maxRetriesBase: Int

    public init(
        backoffStrategy: RetryBackoffStrategy,
        maxRetriesBase: Int = 10
    ) {
        self.backoffStrategy = backoffStrategy
        self.maxRetriesBase = maxRetriesBase
    }
}


public extension RetryStrategyOptions {

    static var standard = RetryStrategyOptions(backoffStrategy: LegacyRetryBackoffStrategy())
}

struct LegacyRetryBackoffStrategy: RetryBackoffStrategy {
    func computeNextBackoffDelay(attempt: Int) -> TimeInterval {
        0.0
    }
}
