//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval
import struct SmithyRetriesAPI.RetryStrategyOptions
import protocol SmithyRetriesAPI.RetryBackoffStrategy

public enum ProtocolTestRetryStrategyOptions {

    public static func make() -> RetryStrategyOptions {
        return RetryStrategyOptions(backoffStrategy: ProtocolTestRetryBackoffStrategy())
    }
}

private struct ProtocolTestRetryBackoffStrategy: RetryBackoffStrategy {

    // Never delays the next retry.
    func computeNextBackoffDelay(attempt: Int) -> TimeInterval { 0.0 }
}
