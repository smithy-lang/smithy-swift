//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct RetryStrategyOptions {
    public let retryMode: RetryMode
    public let maxRetriesBase: Int

    public init(
        retryMode: RetryMode = .standard,
        maxRetriesBase: Int = 10
    ) {
        self.retryMode = retryMode
        self.maxRetriesBase = maxRetriesBase
    }
}
