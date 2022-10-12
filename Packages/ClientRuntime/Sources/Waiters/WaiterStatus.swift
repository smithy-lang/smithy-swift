//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `WaiterStatus` events are returned asynchronously while waiting, to inform
/// the caller of the status of waiting.  Unhandled errors encountered while waiting
/// will be thrown by the waiter iterator rather than returned as waiter status events.
public enum WaiterStatus<Output> {
    case success(Output)
    case retry(WaiterRetryInfo)
}

/// `WaiterRetryInfo` is provided to a caller when a wait operation retries,
/// to keep the caller informed about the progress and status of waiting.
public struct WaiterRetryInfo {
    public let attempt: Int
    public let timeUntilNextAttempt: TimeInterval
    public let timeUntilTimeout: TimeInterval
}
