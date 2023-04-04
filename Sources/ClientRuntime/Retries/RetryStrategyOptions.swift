//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval
import AwsCommonRuntimeKit

public struct RetryStrategyOptions {
    public let maxRetriesBase: Int

    public init(
        maxRetriesBase: Int = 10
    ) {
        self.maxRetriesBase = maxRetriesBase
    }
}
