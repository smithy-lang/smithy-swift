//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct RetryStrategyOptions {
    public static var `default` = RetryStrategyOptions(backoffStrategy: ExponentialBackoffStrategy.default, maxRetriesBase: 3)
    
    public let backoffStrategy: RetryBackoffStrategy

    /// This is more of a hint since a custom retry strategy could be aware of certain operational contexts ("partition fail over")
    public let maxRetriesBase: Int
}
