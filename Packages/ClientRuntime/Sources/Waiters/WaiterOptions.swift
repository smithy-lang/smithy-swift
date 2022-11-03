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

    /// The minimum delay between retries while waiting.  If `nil`, the default for the `Waiter` is used.
    let minDelay: TimeInterval?

    /// The maximum delay between retries while waiting.  If `nil`, the default for the `Waiter` is used.
    let maxDelay: TimeInterval?

    /// The maximum time to spend waiting for the retry to succeed, before a timeout error is thrown.
    let maxWaitTime: TimeInterval

    /// Creates a new set of `WaiterOptions`
    /// - Parameters:
    ///   - minDelay: The minimum delay between retries while waiting.  If `nil`, the default for the `Waiter` is used.
    ///   - maxDelay: The maximum delay between retries while waiting.  If `nil`, the default for the `Waiter` is used.
    ///   - maxWaitTime: The maximum time to spend waiting for the retry to succeed, before a timeout error is thrown.
    public init(
        maxWaitTime: TimeInterval,
        minDelay: TimeInterval? = nil,
        maxDelay: TimeInterval? = nil
    ) {
        self.maxWaitTime = maxWaitTime
        self.minDelay = minDelay
        self.maxDelay = maxDelay
    }
}
