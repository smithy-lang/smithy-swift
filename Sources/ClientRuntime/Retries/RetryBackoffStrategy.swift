//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Determines the time to delay the next retry
/// > Note: Based on _The Design and Implementation of the AWS SDKs_ section 3.2.1, The Smithy Retry Interface, `ExponentialBackOffJitterType`.
public protocol RetryBackoffStrategy {

    /// Returns a Duration that a caller performing retries should use for
    /// delaying between retries. In a green-threads context, this would be
    /// the value indicating the value to set for a timer or time scheduled
    /// task.
    ///
    /// In interrupt driven computing models
    /// (e.g. golang and blocking-IO only models) this would be the value to
    /// pass to a sleep() call.
    ///
    /// A theoretical edge case here to watch out for... integers overflow.
    /// Eventually this code would turn the delay ticks value past the
    /// maximum value for a fixed-width integer. In the case of an overflow,
    /// return the maximum valid representable value.
    func computeNextBackoffDelay(attempt: Int) -> TimeInterval
}
