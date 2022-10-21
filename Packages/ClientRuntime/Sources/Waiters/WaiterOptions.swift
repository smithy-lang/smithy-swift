//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The parameters to be used for an individual wait.  Used when calling a `waitUntil` method.
/// Parameters supplied by these options override those in the `Waiter` object's `WaiterConfig`.
public struct WaiterOptions {
    let minDelay: TimeInterval?
    let maxDelay: TimeInterval?
    let maximumWaitTime: TimeInterval

    /// Creates a new set of `WaiterOptions`
    /// - Parameters:
    ///   - minDelay: The minimum delay between retries while waiting.  If `nil`, the default for the `Waiter` is used.
    ///   - maxDelay: The maximum delay between retries while waiting.  If `nil`, the default for the `Waiter` is used.
    ///   - maximumWaitTime: The maximum time to spend waiting for the retry to succeed, before a timeout error is thrown.
    public init(minDelay: TimeInterval? = nil, maxDelay: TimeInterval? = nil, maximumWaitTime: TimeInterval) {
        self.maximumWaitTime = maximumWaitTime
        self.minDelay = minDelay
        self.maxDelay = maxDelay
    }
}
