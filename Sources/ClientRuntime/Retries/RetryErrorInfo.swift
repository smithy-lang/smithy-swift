//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `RetryErrorInfo` contains parameters describing how an operation error should be retried.
///
/// > Note: Based on _The Design and Implementation of the AWS SDKs_ section 3.2.1, The Smithy Retry Interface, `RetryErrorInfo`.
public struct RetryErrorInfo {

    /// The error type for the described error.
    public let errorType: RetryErrorType

    /// Protocol hint. This could come from HTTP’s ’retry-after’ header or
    /// something from MQTT or any other protocol that has the ability to
    /// convey retry info from a peer.
    public let retryAfterHint: TimeInterval?

    /// Note: we can add additional protocol hints here over time without
    /// breaking the interface (not assuming ABI here,
    /// that’s an exercise for the implementor to figure out if they intend
    /// on preserving ABI compatibility).

}
